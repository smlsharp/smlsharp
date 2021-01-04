/*
 * control.c
 * @copyright (c) 2007-2019, Tohoku University.
 * @author UENO Katsuhiro
 */

#include "smlsharp.h"
#ifndef WITHOUT_MASSIVETHREADS
#include <myth/myth.h>
#endif
#include <stdlib.h>
#include <unistd.h>
#include "object.h"
#include "heap.h"

#ifdef WITHOUT_MASSIVETHREADS
#undef user_tlv_alloc
#undef user_tlv_init
#undef user_tlv_get
#undef user_tlv_set
#define user_tlv_alloc(a,b,c)
#define user_tlv_init(x) (void)0
#define user_tlv_get(x) 0
#define user_tlv_set(x,y) (void)0
#define myth_is_myth_worker() 0
#endif

#ifdef GCHIST
#include "dbglog.h"
#endif

#ifdef GCTIME
#include "timer.h"
static struct {
	sml_timer_t exec_start;
	sml_timer_t sync1_start;
	sml_timer_t sync2_start;
	sml_timer_t mark_start;
	sml_timer_t async_start;
	sml_time_t sync1, sync2, mark, reclaim;
	unsigned int mark_retry;
} gctime;
#endif

/* 各ユーザースレッドについてSML#ランタイムが管理するユーザーコンテキスト．
 * 以下，スレッドとコンテキストの区別が必要な場合は「ユーザースレッド」
 * 「ユーザーコンテキスト」と言い，不要な場合は単に「ユーザー」と言う． */
struct sml_user {
	/* ユーザースレッドがワーカースレッド間を移動したことに伴う
	 * ルートセット列挙の競合を調停するための排他ロックBUSY_FLAGを持つ．*/
	_Atomic(unsigned int) flags;
	/* struct sml_workerのusersリストを構成するために使われるポインタ．
	 * これはユーザーコンテキストの一部ではなく，ワーカーコンテキストの
	 * 一部である．*/
	struct sml_user *next;
	/* ユーザーコンテキストが属するワーカーコンテキストへのポインタ．
	 * ユーザースレッドがワーカースレッド間を移動したことを検出するために
	 * 用いる．移動前と移動後のワーカーコンテキストが共にアクセスするため
	 * アトミック型とする．*/
	_Atomic(struct sml_worker *) worker;
	/* ルートセットを構成するスタックフレームアドレスの範囲のスタック．
	 * ルートセット列挙をするときに用いる．ユーザースレッドがMLコードを
	 * 実行している間は必ず少なくとも1つの要素を持つ．*/
	struct frame_stack_range {
		void *bottom, *top;
		struct frame_stack_range *next;
	} *stack;
	/* 例外がraiseされてからhandleされるまでの間に一旦MLコードを離れる
	 * ときに，raiseされた例外オブジェクト（MLのexnではなく，それを運ぶ
	 * Itanium ABIのオブジェクト）を生かしておくためのポインタ．
	 * このようなことが起こるのは，コールバック関数を超えてMLの例外を
	 * 伝播させるときである．コールバック関数の中で捕捉されない例外が
	 * 発生したとき，一旦Cコードに戻るため，コールバック関数のトップレベル
	 * コードのcleanupハンドラからsml_endが呼び出される．この例外が
	 * MLコードにhandleされsml_enterが呼び出されるまでの間に，C++コードが
	 * 設定したcleanupハンドラが起動され，C++コードが実行され，そこから
	 * MLのコールバック関数が実行される可能性がある．exn_objectはそのような
	 * MLコードの実行から処理中の例外オブジェクトを守るための領域である．
	 * なお，ML例外を処理中にC++コードのcleanupハンドラからコールバック
	 * されたML関数がそのML関数内で捕捉されない例外を投げた時は
	 * （つまりexn_objectがNULLでないときにさらにexn_objectに書き込
	 * もうとしたら），C++と同様に，プログラムを強制終了する．*/
	void *exn_object;
};

/* 各ワーカースレッドについてSML#ランタイムが管理するワーカーコンテキスト．
 * 以下，スレッドとコンテキストの区別が必要な場合は「ワーカースレッド」
 * 「ワーカーコンテキスト」と言い，不要な場合は単に「ワーカー」と言う． */
struct sml_worker {
	/* 現在のワーカーコンテキストの状態を表す状態変数．コレクタとワーカーが
	 * 共にアトミックに読み書きする．下位3ビットにフェーズを，5ビット目に
	 * INACTIVEフラグ（0ならACTIVEである）を持つ（0をACTIVEにしたのは
	 * アトミックビット演算の効率のためである）．
	 * フェーズは，コレクタからのアクション依頼（シグナル）とその受理状況と
	 * 理解するとわかりやすい．
	 * シグナルはASYNC, SYNC1, SYNC2, MARKの4つある．これらのうちSYNC2と
	 * MARKシグナルは，他のシグナルがペンディングのときに受け取ることは
	 * ない．ASYNCとSYNC1シグナルについては，ASYNCがペンディングのときに
	 * SYNC1を受け取ることがあり，従って2つのシグナルが同時にペンディング
	 * になることがある．
	 * PREから始まるフェーズは，シグナルが届いたがペンディングであることを
	 * 表す．そうでないフェーズは，同名のシグナルが受理された状態を表す．
	 * 「受理した状態」とは「アクションの実行を完了した状態」ではないこと
	 * に注意．アクションは「受理した状態」に移行してから実行される．
	 * アクションの完了はsml_check_flagをデクリメントすることによって
	 * 通知される．
	 * ACTIVEなワーカーコンテキストにアクション依頼が来た場合は，その
	 * ワーカーコンテキストをACTIVEにしたスレッドがそのアクションを
	 * 実行する責任を持つ．*/
	_Atomic(unsigned int) state;
	/* GCの進行（シグナル）とは無関係のフラグ．以下の3つのフラグを持つ．
	 * 他のワーカースレッドがヘルプに入っているとき，本来の持ち主である
	 * スレッドが cancel_worker を呼ぶ可能性があるため，_Atomicにしている．
	 *   PTHREAD_FLAG  - このスレッドはMassiveThreadのワーカーではない
	 *   CANCELED_FLAG - このスレッドはキャンセルされた（終了された）
	 *   DEAD_FLAG - このスレッドの全ての資源は解放された（削除できる）
	 *   GLOBALENUM_FLAG - グローバル変数の列挙をする責任を持っている
	 *                     worker_sync1でセットされworker_sync2でリセット
	 *                     される
	 */
	_Atomic(unsigned int) flags;
	/* このワーカーコンテキストに属するユーザーコンテキストのリスト．
	 * ユーザースレッドとワーカースレッドの所属関係と，
	 * ユーザーコンテキストとワーカーコンテキストの所属関係は必ずしも
	 * 同期しないことに注意．*/
	struct sml_user *users;
	/* このワーカーコンテキストが現在のユーザーコンテキストを覚えておく
	 * ための領域．「現在のユーザーコンテキスト」を表す変数には，
	 * worker->current_userとuser_tlv_get(current_user)の2つがある．
	 * ユーザースレッドがMLコードを実行している間は前者が，そうでない
	 * ときは後者が，現在のユーザーコンテキストを指す．MLコードにいるときは
	 * user_tlv_get(current_user)はNULLであるようにメンテナンスする．
	 * MLコードを離れないユーザースレッドでは後者は使用されない．
	 * このスレッドがpthreadのとき，MLコードを実行中かどうかにかかわらず，
	 * worker->current_userは唯一のユーザーコンテキストを指し続ける．
	 * ユーザースレッドローカル変数へのアクセスは遅いので，できるだけ
	 * 減らしたい．特に，全てのスレッドが通過するsml_startやsml_endでは
	 * 呼び出したくない．*/
	struct sml_user *current_user;
	/* このワーカーコンテキストが管理するアロケーションポインタ */
	struct sml_alloc *allocator;
	/* 全ワーカーコンテキストのリストworkers_availableを構成するための
	 * ポインタ．これはワーカーコンテキストの一部ではなく，
	 * workers_availableの一部である．*/
	struct sml_worker *next;
	/* sml_check_internalが呼ばれるときに実行されるフック */
	void (*check_hook)(void);
};

/* 4つのシグナルASYNC, SYNC1, SYNC2, MARKに対し，8つのフェーズが定義される．
 * フェーズはシグナルの発行・受理に合わせて以下の図の通り遷移する．
 *    ASYNC -!-> PRESYNC1 --> SYNC1 -!-> PRESYNC2
 *      ^                                   |
 *      |                                   v
 *    PREASYNC <-!- MARK <-- PREMARK <-!- SYNC2
 * !が付いた矢印はシグナルの発行による遷移を表す．他の矢印はシグナルの受理に
 * よる遷移である．この遷移を単純なビット演算で実現するため，各フェーズの
 * 具体的な値を以下の通り定める．（定義はsmlsharp.hにある）
 *   PREASYNC          = 000
 *   ASYNC             = 001
 *   PRESYNC1          = 010
 *   SYNC1             = 011
 *   PRESYNC2          = 100
 *   SYNC2             = 101
 *   PREMARK           = 110
 *   MARK              = 111
 * シグナルの発行によるフェーズ遷移は以下の値をフェーズにXORすることで行う．
 *   ASYNCの発行 : MARK ^ PREASYNC
 *   SYNC1の発行 : ASYNC ^ PRESYNC1
 *   SYNC2の発行 : SYNC1 ^ PRESYNC2
 *   MARKの発行  : SYNC2 ^ PREMARK
 * シグナルの受理によるフェーズ遷移はPREフェーズに 001 をORすることで行う．
 * PREでないフェーズに 001 をORしてもフェーズは変化しない．
 */
#define PHASE_MASK       0x07U
#define INACTIVE_STATE   0x10U
#define HELPER_STATE     0x20U
#define PHASE(state)     ((state) & PHASE_MASK)
#define ACTIVE(phase)    (phase)
#define INACTIVE(phase)  ((phase) | INACTIVE_STATE)
#define IS_ACTIVE(state) (!((state) & INACTIVE_STATE))
#define BUSY_FLAG        0x01U
#define CANCELED_FLAG    0x02U
#define DEAD_FLAG        0x04U
#define GLOBALENUM_FLAG  0x08U
#define PTHREAD_FLAG     0x10U
#define IS_PTHREAD(worker) (load_relaxed(&(worker)->flags) & PTHREAD_FLAG)

#define PTROR(p,x)   (void*)((uintptr_t)(p) | (x))
#define PTRAND(p,x)  (void*)((uintptr_t)(p) & (x))

static inline int
acquire_bit(_Atomic(unsigned int) *flags, unsigned int bit)
{
	/* alternative to (fetch_or(acquire, flags, bit) & bit) != 0 */
	unsigned int old;

	/* リードしてビットテストしてから，ビットを立てられる可能性のある
	 * ときだけアトミックライト命令を実行する．
	 * これにより，ビットが変化するまでの間キャッシュにのみアクセスし
	 * メモリバスを消費しないため，他のCPUの実行を妨げない */
	old = load_relaxed(flags);
	if ((old & bit) != 0)
		return 0;
	return cmpswap_weak_acquire(flags, &old, old | bit);
}

static inline int
acquire_unbit(_Atomic(unsigned int) *flags, unsigned int bit)
{
	/* alternative to (fetch_and(acquire, flags, ~bit) & bit) == 0 */
	unsigned int old;

	/* リードしてビットテストしてから，ビットを消せる可能性のある
	 * ときだけアトミックライト命令を実行する．
	 * これにより，ビットが変化するまでの間キャッシュにのみアクセスし
	 * メモリバスを消費しないため，他のCPUの実行を妨げない */
	old = load_relaxed(flags);
	if ((old & bit) == 0)
		return 0;
	return cmpswap_weak_acquire(flags, &old, old & ~bit);
}

/* 全ワーカーコンテキストを保持するリスト．
 * 下3ビットには新しく追加されるワーカーコンテキストのフェーズが格納される．
 * PHASE(worker->state)がそのフェーズでないworkerをworkers_availableに
 * に追加してはならない．ただし，下3ビットが0のときはプログラム終了を表す．
 * 下3ビットを別の情報に利用するため，struct sml_workerのアドレスの下3ビットは
 * 0でなければならない．sml_alloc で確保すると struct sml_worker（40バイト）
 * は64ビット境界に配置されるので，アドレスの下5ビットは0であり，
 * この条件を満たす．
 */
static _Atomic(struct sml_worker *) workers_available = PTROR(NULL, ASYNC);

/* 現在進行中のハンドシェークに参加するワーカーコンテキストのリスト．
 * このリストに入っているワーカーのうち，INACTIVE(PRE...)をstateに持つ
 * ワーカーコンテキストのアクションは，他のワーカースレッドが肩代わりして
 * 実行する．ABA問題を防ぐため，下3ビットには現在のPREありフェーズが入る．
 */
static _Atomic(struct sml_worker *) workers_handshake;

/* sml_checkを呼ぶ必要があることをユーザースレッドに伝えるフラグ
 * （非0ならオン）．
 * 実際にはフラグではなく，応答すべきワーカーコンテキストの数を表すカウンタ
 * として働く．コレクタが全ワーカーコンテキストのフェーズを変更したとき，
 * フェーズを変更したワーカーコンテキストの数だけコレクタがこのカウンタを
 * インクリメントする．
 * MLコードを実行中のユーザースレッドは定期的にsml_check_flagを見て，
 * 0でなければsml_checkを呼び出す（そういうコードをコンパイラが生成する）．
 * アクションを完了したワーカーはsml_check_flagをデクリメントする．
 * このカウンタは負にもなり得ることに注意．コレクタがワーカーコンテキストの
 * フェーズを変更した直後からsml_check_flagをインクリメントする直前までの間に，
 * フェーズを変更されたワーカーがsml_check_flagをデクリメントするかもしれない．
 */
_Atomic(unsigned int) sml_check_flag;

/* GCの起動と終了をカウントするカウンタ．奇数の場合GCが進行中であることを
 * 表す．偶数の場合，これまでに行ったGCの起動と終了の回数を表す．*/
static _Atomic(unsigned long) gc_count;

static void cancel_worker(void *);
static void cancel_user(void *);

/* ワーカースレッドとワーカーコンテキストを紐づけるスレッドローカル変数 */
worker_tlv_alloc(struct sml_worker *, current_worker, cancel_worker);

/* MLコードを一時離れる時に，ユーザースレッドとユーザーコンテキストの紐付けを
 * 覚えておくためのユーザースレッドローカル変数．
 * 「現在のユーザーコンテキスト」を表す変数には，
 * worker->current_userとuser_tlv_get(current_user)の2つがある．
 * ユーザースレッドがMLコードを実行している間は前者が，そうでない
 * ときは後者が，現在のユーザーコンテキストを指す．
 * MLコードにいるときはuser_tlv_get(current_user)はNULLであるように
 * メンテナンスされる．*/
user_tlv_alloc(struct sml_user *, current_user, cancel_user);

void
sml_control_init()
{
	worker_tlv_init(current_worker);
	user_tlv_init(current_user);
#ifdef GCTIME
	sml_timer_now(gctime.exec_start);
#endif
}

static void
yield()
{
//DBG("yield");
#ifndef WITHOUT_MASSIVETHREADS
	if (myth_is_myth_worker())
		myth_yield_ex(myth_yield_option_local_only);
	else
#endif
		sched_yield();
}

static void cancel_worker(void *p)
{
	struct sml_worker *worker = p;
	unsigned int state;

	/* ワーカースレッド（pthread）が終わろうとするときこの関数が呼ばれる．
	 * スレッドが終わるのは，メイン関数からリターンしたか，OSの機能
	 * （pthread_exitやcancelation）で中断されたかのどちらかである．
	 * cancelationには同期と非同期の2種類がある．
	 * 同期cancelationではシステムコールを呼んだ時にスレッドが中断される．
	 * 非同期cancelationはいつ中断するか制御できない．
	 *
	 * 非同期キャンセルでなければ，スレッドの終了はMLコードでは起こらない
	 * ので，ここに到達したとき，このワーカースレッドはworkerのロックを
	 * 持っていないはずである．従って，worker->stateはINACTIVEであるか，
	 * ヘルパーワーカーがロックを持ってACTIVEにしているかのどちらかである．
	 * そうでなければ，MLコードの実行中に非同期キャンセルが行われた
	 * ことを表す．*/
	state = load_relaxed(&worker->state);
	if (IS_ACTIVE(state) && !(state & HELPER_STATE))
		sml_fatal(0, "thread is canceled asynchronously");

	/* ここに到達したということは，このワーカースレッドに属する
	 * ユーザースレッドは存在しないか，存在しても全員死んでいるはず
	 * である．しかし，ワーカーコンテキストにはまだユーザーコンテキストが
	 * 属している可能性がある．例えば，ユーザースレッドは別のワーカー
	 * スレッドに移動したが，その移動がまだワーカーコンテキストに反映されて
	 * いない場合などである．全てのユーザーコンテキストがこのワーカー
	 * コンテキストから取り除かれるまで，このワーカーコンテキストを削除
	 * することができない．ユーザーコンテキストの他にも，リメンバーセットや
	 * コレクトビットマップなどの資源がこのワーカーコンテキストには
	 * 存在する．これらの資源が全て確実に消費されない限り，このワーカー
	 * コンテキストを削除することはできない．そこで，ここではワーカーが
	 * キャンセルされたことを表すフラグだけ立てる．ハンドシェークへの影響を
	 * 避けるためフラグはstateではなくflagsに立てる．
	 * worker->users が空であること，リメンバーセットが空であること，
	 * コレクトビットマップがクリアであることの確認は change_phase で行う．
	 *
	 * workerはINACTIVEであるか，他のヘルパーワーカーがロックを持って
	 * ACTIVEにしているかのどちらかである．後者の場合，worker->flagsに
	 * 対してレースが発生する可能性がある．従ってここのflagsへの書き込みは
	 * アトミックでなければならない．*/
	fetch_or(release, &worker->flags, CANCELED_FLAG);
//DBG("cancel_worker worker=%p", worker);
}

static void cancel_user(void *p)
{
	struct sml_user *user = p;

	/* myth_key_initのデストラクタ関数は変数の中身がNULLでも呼び出される
	 * ことに注意 */
	if (!user)
		return;

	/* MLコードにいる間はcurrent_userはNULLなので，ここに到達するのは
	 * myth_exitを呼んだときか，myth_cancelされた状態でmyth_testcancelを
	 * 呼んだときのどちらかである．
	 * 従って，この文脈ではuserへの排他アクセスがない．この関数の実行と
	 * と同時に，他のワーカースレッドがuserのルートセット列挙をしている
	 * 可能性がある．その一方で，この関数からリターンすると，このユーザー
	 * のスタックフレームが解放されてしまう．この関数から出た後はルート
	 * セット列挙が行われないことを確実にしなければならない．そのために
	 * ここでBUSY_FLAGロックを取り，user->workerを書き換える．
	 * これによって現在進行中のルートセット列挙を待った上で，ワーカー
	 * コンテキストからこのユーザーコンテキストを削除させる．*/
	while (!acquire_bit(&user->flags, BUSY_FLAG))
		yield();
	store_relaxed(&user->worker, NULL);
	store_release(&user->flags, CANCELED_FLAG);
}

struct sml_alloc_cons
sml_next_allocator(struct sml_worker *worker)
{
	struct sml_alloc_cons c;

	/* 完全に死んだワーカーコンテキストを取り除く */
	while (worker && (load_relaxed(&worker->flags) & DEAD_FLAG) != 0)
		worker = worker->next;

	c.alloc = worker ? worker->allocator : NULL;
	c.next = worker ? worker->next : NULL;
	return c;
}

struct sml_alloc_cons
sml_get_allocators()
{
	struct sml_worker *worker;

	worker = load_acquire(&workers_available);
	/* workers_availableの下3ビットには，新しく追加されるワーカー
	 * コンテキストが持つべきフェーズが格納されている．これを取り除く */
	worker = PTRAND(worker, ~(uintptr_t)PHASE_MASK);

	return sml_next_allocator(worker);
}

static enum sml_sync_phase
register_worker(struct sml_worker *worker)
{
	enum sml_sync_phase phase;
	struct sml_worker *old, *new, *next;

	/* この関数は新しいワーカーを追加する．
	 * workers_availableの下3ビットは，新しく追加されるワーカーコンテキスト
	 * のフェーズが格納される場所である．新しいワーカーコンテキストの
	 * アドレスの下3ビットが空いていることを確認する．*/
	assert(((uintptr_t)worker & PHASE_MASK) == 0);

	old = load_acquire(&workers_available);
	do {
		/* workers_availableの下3ビットには，新しく追加されるワーカー
		 * コンテキストが持つべきフェーズが格納されている．
		 * これを取り出し，新しいワーカーコンテキストにセットしてから，
		 * workers_availableに加える．
		 * 新しいワーカーコンテキストのアドレスの下3ビットにも
		 * フェーズ情報を格納する．この一連の操作は不可分である．
		 * ワーカーがこれらの操作をしている間にコレクタは次の
		 * フェーズに進んではならない．*/
		phase = PHASE((uintptr_t)old);
		if (phase == 0) {
			/* phaseが0のとき，ランタイムシステムは終了処理に
			 * 入っており，新しいワーカーの登録が禁止されている．
			 * もはや何もすることがないのでこのスレッドを止めたいが
			 * pthread_exitするとpthead_keyのdescrutorが呼ばれる
			 * かもしれないので，pthread_exitは使わない．
			 * 本当に何もして欲しくないので無限ループする */
			for(;;)
				sleep(-1U);
		}

		/* workers_availableの先頭にいる完全に死んだワーカーコンテキ
		 * ストを取り除き，最初の生きているワーカーコンテキストを
		 * 新しいワーカーコンテキストのnextとする．
		 * このようにしてworkers_availableの先頭にはできるだけ生きて
		 * いるワーカーコンテキストが来るようにメンテナンスする．*/
		next = PTRAND(old, ~(uintptr_t)PHASE_MASK);
		while (next && (load_relaxed(&next->flags) & DEAD_FLAG) != 0) {
//DBG("register_worker kill %p", next);
			next = next->next;
		}
		worker->next = next;
		atomic_init(&worker->state, ACTIVE(phase));
		/* workers_availableの下3ビットにフェーズ情報を埋め込む */
		new = PTROR(worker, phase);
	} while (!cmpswap_weak_acq_rel(&workers_available, &old, new));

	return phase;
}

static struct sml_worker *
global_phase(enum sml_sync_phase new_phase)
{
	struct sml_worker *old, *new, *ret;

	/* この関数はハンドシェークする対象のワーカーコンテキストの集合を
	 * 確定する．ワーカー集合が確定した瞬間よりも後に生まれた新規
	 * ワーカーコンテキストには，すでにハンドフェークを終えた状態を持た
	 * せる．これにより，ハンドシェークが終わった後は，ハンドシェーク中に
	 * 追加されたワーカーも含めて，全てのワーカーがハンドシェークを終えた
	 * 状態になる．この状況を作るためには，ワーカーコンテキスト集合の確定
	 * と，これから生まれるワーカーコンテキストのフェーズの指定は不可分で
	 * なければならない．この不可分な操作をlock-freeで行うために，
	 * workers_availableの下3ビットにフェーズを埋め込む．*/
	assert((new_phase & ~PHASE_MASK) == 0 && new_phase != 0);

	old = load_acquire(&workers_available);
	do {
		/* workers_availableの先頭にいる完全に死んだワーカーコンテキスト
		 * を取り除き，最初の（この操作をした瞬間には）生きている
		 * ワーカーコンテキストを返り値とする．
		 * このようにしてworkers_availableの先頭にはできるだけ生きて
		 * いるワーカーコンテキストが来るようにメンテナンスする．*/
		ret = PTRAND(old, ~(uintptr_t)PHASE_MASK);
		while (ret && (load_relaxed(&ret->flags) & DEAD_FLAG) != 0) {
//DBG("global_phase kill %p", ret);
			ret = ret->next;
		}
		/* workers_availableの下3ビットにnew_phaseを埋め込む */
		new = PTROR(ret, new_phase);
	} while (!cmpswap_weak_acq_rel(&workers_available, &old, new));

	return ret;
}

struct enter_worker {
	struct sml_user *new_user;
	struct sml_worker *worker;
};

static struct enter_worker
enter_worker()
{
	struct sml_heap_worker_init init;
	struct sml_worker *worker;
	struct sml_user *new_user;
	enum sml_sync_phase phase;

retry:
	worker = worker_tlv_get(current_worker);

	if (worker) {
		/* workerをACTIVEにして排他ロックを獲得する．
		 * このacquireに対応するreleaseはleave_workerにある．*/
		if (!acquire_unbit(&worker->state, INACTIVE_STATE)) {
			/* ロックが直ちに取れなかったということは，他のワーカー
			 * スレッドがこのworkerに対して，このスレッドの代わりに
			 * 何かのアクションをしているということである．
			 * 他のワーカースレッドがアクションを終えてロックを解放
			 * するまでここで待つ．
			 * アクションの完了までは結構時間がかかるはずである．
			 * 待っている間の時間を使って他のユーザースレッドを
			 * 進めることもやってみたが，結局のところ，ビジーループ
			 * で待つのが最も効率的なようだ．
			 */
#if 1
			while (!acquire_unbit(&worker->state, INACTIVE_STATE))
				asm_pause();
#else
			/* 待っている間に他のユーザースレッドにCPUを譲る方法も
			 * なくはない．myth_yieldは1/2の確率でワークスティール
			 * するので，ビジーループの中で呼ぶととてつもなく遅い．
			 * 同じワーカーのユーザースレッドに譲るyield_exが最も
			 * 軽量なので，ここで呼ぶ選択肢の中では最も良い．
			 * しかしなぜか，ここでyieldするとGCの回数が増え，
			 * GC時間も長くなるようだ．原因はよくわからない．
			 * 単にスピンロックして無駄にCPUを消費するよりはマシな
			 * 気がするのだが，実際はそうでもないようだ．
			 *
			 * 譲る先のユーザースレッドもMLコードでないところで
			 * 止まっているはずなので，長いC関数を実行している
			 * とかでない限りは直ちにenterしてきて，結局のところ，
			 * ここに到達したユーザースレッドの間でyieldし合うだけ
			 * のビジーループになる．
			 *
			 * myth_yieldから帰ってきたらワーカーが違うかもしれない
			 * ことに注意 */
			yield();
			goto retry;
#endif
		}
		return ((struct enter_worker)
			{.new_user = NULL, .worker = worker});
	} else {
		/* このワーカースレッドのワーカーコンテキストはまだ存在しない
		 * ため，アロケータとワーカーコンテキストをここで新しく作る．
		 * サイズを2のべき乗にまるめる戦略の下でメモリを有効に使うため，
		 * アロケータ，ワーカーコンテキスト，およびユーザーコンテキスト
		 * を全て一度にアロケートする．*/
		size_t user_offset = CEILING(sizeof(struct sml_worker),
					     alignof(struct sml_user));
		size_t allocsize = user_offset + sizeof(struct sml_user);
		init = sml_heap_worker_init(allocsize);
		if (!init.alloc) {
			/* アロケータをGCなしで確保できない状況では
			 * このワーカーの実行を開始することができない．
			 * そのため，このユーザースレッドの実行を諦めざるを
			 * 得ない．一旦他のユーザースレッドにCPUを譲る．*/
			yield();
			goto retry;
		}
		worker = init.memory;
		new_user = (void*)((char*)init.memory + user_offset);

		store_relaxed(&worker->flags, 0);
		worker->allocator = init.alloc;
		worker->users = NULL;
		worker->check_hook = NULL;
		if (myth_is_myth_worker()) {
			atomic_init(&worker->flags, 0);
			/* worker->current_userはenter_workerを呼び出した
			 * 関数が必ずセットするのでNULLクリアは不要 */
			DEBUG(worker->current_user = NULL);
		} else {
			atomic_init(&worker->flags, PTHREAD_FLAG);
			/* PTHREAD_FLAGが立っているワーカーはユーザーをただ
			 * ひとつだけ持つ．worker->current_userはこの唯一の
			 * ユーザーを常に指す．
			 * sml_startがユーザースレッドの開始を識別できるように
			 * worker->current_userをNULLに初期化する */
			worker->current_user = NULL;
		}

		phase = register_worker(worker);
		sml_heap_worker_register(init.alloc, phase);
		worker_tlv_set(current_worker, worker);

		return ((struct enter_worker)
			{.new_user = new_user, .worker = worker});
	}
}

static void worker_sync1(struct sml_worker *worker, int greedy);
static void worker_sync2(struct sml_worker *worker, int greedy);
static void worker_mark(struct sml_worker *worker, int greedy);
static void worker_async(struct sml_worker *worker);

static void
leave_worker(struct sml_worker *worker)
{
	unsigned int old;

	assert(IS_ACTIVE(load_relaxed(&worker->state)));
	assert(worker->current_user == NULL
	       || worker->current_user->stack == NULL
	       || worker->current_user->stack->top != NULL);

	/* workerの排他ロックを解放する．
	 * さらに同時に1と論理和を取ることで，PRE付きフェーズをPREなしフェーズ
	 * に進める．PREなしフェーズの場合は何も起こらない．
	 * そうなるようにフェーズ定数が定義されている．
	 * ここのreleaseに対応するacquireはenter_workerとhelp_inactiveにある．
	 */
	old = fetch_or(release, &worker->state, INACTIVE_STATE | 1);

	/* アンロックと同時にSYNC1およびSYNC2フェーズに進んだ場合は
	 * アクションを実行する．ヘルパが入る可能性があるためgreedyには
	 * できない */
	switch(old) {
	case ACTIVE(PREASYNC):
		worker_async(worker);
		break;
	case ACTIVE(PRESYNC1):
		worker_sync1(worker, 0);
		break;
	case ACTIVE(PRESYNC2):
		worker_sync2(worker, 0);
		break;
	case ACTIVE(PREMARK):
		worker_mark(worker, 0);
		break;
	}
}

static void
sml_leave_internal(void *frame_pointer)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;

	/* userのスタック範囲を閉じる（topをセット）*/
	assert(user->stack->top == NULL);
	user->stack->top = frame_pointer;

	/* MLコードに復帰するときのためにuserをcurrent_userに覚えておく．
	 * MLコードにいないときworker->current_userは参照されない．
	 * このワーカースレッドがpthreadのときは，worker->current_userが常に
	 * 唯一のユーザーコンテキストを指し続けるので，何もしなくて良い */
	if (!IS_PTHREAD(worker)) {
		assert(user_tlv_get(current_user) == NULL);
		user_tlv_set(current_user, user);
	}

	/* MLコードから離れる．これ以降workerのロックは解放されるので，
	 * workerとuserは他のスレッドからアクセスされる可能性があることに注意．
	 * 従ってleave_workerよりも後にworkerやuserに触れる処理をしては
	 * ならない．*/
	leave_worker(worker);
}

SML_PRIMITIVE void
sml_leave()
{
	sml_leave_internal(CALLER_FRAME_END_ADDRESS());
}

static void
sml_enter_internal(void *frame_pointer ATTR_UNUSED)
{
	struct sml_worker *worker;
	struct sml_user *user, *new_user;
	enum sml_sync_phase phase;

 retry:
	/* MLコードに入る．ワーカーコンテキストがなければ新しく作る．*/
	worker = enter_worker().worker;

	/* sml_enterはsml_leaveの後にしか呼び出されないので，
	 * user_tlv_get(current_user)はNULLでないはずである．
	 * このスレッドがpthreadの場合はworker->current_userが唯一の
	 * ユーザーコンテキストを常に指している．*/
	user = IS_PTHREAD(worker) ?
		worker->current_user : user_tlv_get(current_user);
	assert(user != NULL);

	/* このユーザースレッドはワークスティールによって別のワーカースレッド
	 * から移動してきたものかどうかを判定する．もしそうならば前のワーカーと
	 * ルートセット列挙に関する同期を取る必要がある．*/
	if (load_relaxed(&user->worker) != worker) {
		/* userをコピーするためのメモリを確保する．
		 * user->nextは前のワーカーコンテキストが専有するので，
		 * userをリストから外すことはここではできない．そこで，
		 * userをコピーして今のワーカーコンテキストに加えることで
		 * 移動を行う．
		 * このアロケートは，ここのほかに，この後に続くBUSY_STATEロック
		 * の中か，ロックを解放した後に行うことも考えられる．しかし，
		 * ロック中にアロケートした場合，セグメントのアロケーションなど
		 * の遅い処理が行われロック時間が伸びる可能性がある．
		 * ロック解放後にアロケートした場合，アロケーションが失敗した
		 * 場合のフォールバック処理を考えなければならず，それはかなり
		 * 複雑になると考えられる（実際に数日考えてみたが完成しな
		 * かった）．どちらも好ましくないので，ここでアロケートする
		 * ことにする．*/
		phase = PHASE(load_relaxed(&worker->state));
		new_user = sml_alloc_important(worker->allocator,
					       sizeof(struct sml_user),
					       phase);
		if (!new_user) {
			/* GCするタイミングを制御するコードの中でGCを待つことは
			 * できないので，GCなしでアロケートできない状況では，
			 * ユーザーの移動処理を進められない．このユーザーの
			 * 実行を諦めて，最初からやり直さざるを得ない．
			 * 一旦MLコードを抜けて他のユーザースレッドにCPUを
			 * 譲る．*/
			leave_worker(worker);
			yield();

			/* myth_yieldから帰ってきたらワーカースレッドが違う
			 * かもしれないので先頭からやり直す */
			goto retry;
		}
		OBJ_HEADER(new_user) = sizeof(struct sml_user);

		/* 他のワーカーがsync2アクションを行なっている可能性を
		 * 自分のフェーズから判定する．自分のフェーズがPRESYNC1以前
		 * ならば，他のワーカーはSYNC1までしか進んでいないはずなので
		 * sync2アクションは行なっていない．自分がPREMARK以降ならば，
		 * 全てのワーカーのsync2アクションは終わっているはずである．
		 * 以上のどちらでもない場合，すなわちSYNC1からSYNC2の間が，
		 * sync2アクションが行われている可能性がある場合である．
		 * なお，前のワーカーのstateを見ても，前のワーカーが列挙を
		 * 行ったかどうかは分からないことに注意．SYNC2フェーズはあくまで
		 * シグナルの受理を表すので，前のワーカーがworker_sync2を
		 * 実行する前に，前のワーカーのフェーズはSYNC2になる．また，もし
		 * 前のワーカーがPRESYNC2であることを観測したとしても，
		 * 観測した直後にはSYNC2に遷移している可能性がある．*/
		phase = PHASE(load_acquire(&worker->state));
		if (SYNC1 <= phase && phase <= SYNC2) {
			/* 前のワーカーがルートセット列挙の途中である可能性が
			 * ある．このユーザーのロックを取得し排他的アクセスを
			 * 確保することで，他のワーカーによるルートセット列挙
			 * 途中の可能性を排除する．*/
			if (!acquire_bit(&user->flags, BUSY_FLAG)) {
				/* ロックが取れなければ，前のワーカーがルート
				 * セット列挙している途中なので，ルートセット
				 * 列挙が終わるのを待つ．ワークスティールされ
				 * てきたということは，このワーカースレッドは
				 * このユーザースレッド以外のユーザースレッド
				 * を持っていない可能性が高い．そのため，yield
				 * しても意味がないと思われる（このスレッドは
				 * 実行できないから別のスレッドをスティールして
				 * ほしい，というヒントをMassiveThreadsに与え
				 * られると良いかもしれない．myth_mutex_lockを
				 * 使えば良い？）．簡単のため，ここではビジー
				 * ループしてルートセット列挙完了を待つことに
				 * する．*/
				do {
					asm_pause();
				} while (!acquire_bit(&user->flags, BUSY_FLAG));

				/* ロックされていたことを一度観測しているので，
				 * ロックが確保できたということは，前のワーカー
				 * がこのユーザーのルートセット列挙を完了した，
				 * ということである．従って，userは今回のGCを
				 * 必ず生き残る．一方，new_userはSYNC2フェーズ
				 * までにこのワーカースレッドによってアロケート
				 * されたオブジェクトであるから，このワーカーが
				 * MARKフェーズになるまでは回収されない．
				 * 従って，userとnew_userは少なくともこの関数が
				 * 終わるまでの間は回収されない．*/
			} else {
				/* すんなりロックが取れたということは，この
				 * ユーザーのルートセット列挙はまだ始まって
				 * いないか，すでに終わっているかのどちらか
				 * である．このワーカーコンテキストのルート
				 * セット列挙がまだ終わっていないならば，この
				 * ユーザーコンテキストをこのワーカーコンテキ
				 * ストに登録するだけでよいので，ここでは何も
				 * しなくて良い．そうでなければ，すべての
				 * ワーカーがsync2アクションを終える前に
				 * このユーザーのルートセット列挙を完了する
				 * 必要がある．*/
				if (phase == SYNC2) {
					/* このワーカーはすでに列挙を終えてい
					 * るが，システム全体で列挙を終えてい
					 * るかどうかはわからないとき，安全の
					 * ため，このユーザーの列挙をここで
					 * 行う．
					 * すでに前のワーカーによってこの
					 * ユーザーの列挙が行われていたとき，
					 * ここでの列挙は無駄な操作である．
					 * このワーカーはこのユーザーの列挙を
					 * すでに終えているため，GCはSYNC2を
					 * 超えてさらに先に（MARKに）進んでいる
					 * 可能性がある．
					 * sml_heap_user_sync2はMARKフェーズで
					 * 呼んでも安全なように作られていると
					 * 仮定する．
					 * 前のワーカーがこのユーザーの列挙を
					 * まだ行っていないとき，ここでの列挙の
					 * 完了を前のワーカーが（BUSY_FLAGロッ
					 * クを取ろうとして）待っているか，
					 * 前のワーカーに先んじて列挙しているか
					 * のどちらかである．
					 * 前者の場合，前のワーカーはここでの
					 * 列挙の完了を待ってからアクションを
					 * 終えるので，ここでの列挙が終わるまで
					 * GCが先に進むことはない．後者の場合，
					 * 前のワーカーによる列挙は無駄な操作に
					 * なるが，ここでの列挙が終わるまで
					 * GCが先に進むことがないことに変わりは
					 * ない．いずれにせよ，すべてのワーカー
					 * が列挙を終える前にこのユーザーの列挙
					 * がかならず起こる．
					 *
					 * このように列挙が行われるので，userは
					 * 今回のGCを必ず生き残る．new_userにつ
					 * いても，このワーカーのルートセット
					 * 列挙以降にこのワーカーによってアロ
					 * ケートされたオブジェクトであるから，
					 * 今回のGCでは回収されない．従って，
					 * userとnew_userは少なくともこの関数が
					 * 終わるまでの間は回収されない．*/
					sml_heap_user_sync2(user,
							    worker->allocator);
				} else {
					/* ここに到達するのは，このワーカーが
					 * SYNC1かPRESYNC2のときである．従って
					 * 他のワーカーはSYNC1かSYNC2にいる．
					 * MARK以降に進むためにはこのワーカーが
					 * sml_check_flagをデクリメントする
					 * 必要があるが，この関数はそれを
					 * 行わないので，この関数が終わるまでの
					 * 間にuserとnew_userは回収されない．
					 * 前のワーカーがuserのルートセット列挙
					 * をしたかどうかはわからない．
					 * 前のワーカーはuserのルートセット列挙
					 * をしようとしてBUSY_FLAG待ちしている
					 * かもしれない．
					 * userのルートセット列挙は，この
					 * ワーカーによって将来行われる．*/
				}
			}
			/* 以上より，ここを通るとき，関数が終わるまでuserと
			 * new_userは生きている．アンロックすると前のワーカーが
			 * ルートセット列挙するかもしれない．このワーカーは
			 * userのルートセット列挙を行ったか行う予定かのどちらか
			 * である．*/

			/* 移動する準備は全て整った．user->workerを変更し，
			 * 前のワーカーにuserを捨てさせる．この書き込みを
			 * ロック解除前に行うことで，前のワーカーがuserの
			 * ルートセット列挙を行う可能性を排除する．*/
			store_relaxed(&user->worker, worker);

			/* ロック解除．user->flagsはBUSY_FLAGしか使わないので
			 * シンプルに0をストアする．*/
			store_release(&user->flags, 0);
		} else {
			/* ここに来るのはこのワーカーがPREMARK, MARK, PREASYNC,
			 * ASYNC, PRESYNC1のときである．
			 * ということは他のワーカーはPREMARK, MARK, PREASYNC,
			 * ASYNC, PRESYNC1, SYNC1である．
			 * どのワーカーもSYNC2になっていないのでどのワーカーも
			 * ルートセット列挙していない．また，他のワーカーが
			 * PRESYNC2に進むには，このワーカーがsml_check_flagを
			 * デクリメントする必要があるが，この関数ではそれを
			 * 行わない．従ってこの関数が終わるまでの間，
			 * userとnew_userは回収されず，かつuserのルートセット
			 * 列挙を前のワーカーは行わない．*/

			/* user->workerを変更し，前のワーカーにuserを
			 * 捨てさせる．どのワーカーもまだworker_sync2に達して
			 * いないので，この書き込みは排他的である */
			store_relaxed(&user->worker, worker);
		}
		/* ここを通るとき，関数が終わるまでuserとnew_userは生きている．
		 * このワーカーはuserのルートセット列挙を行ったか
		 * 行う予定かのどちらかである．*/

		/* userの中身をnew_userにコピーする */
		new_user->stack = user->stack;
		new_user->exn_object = user->exn_object;

		/* new_userをworkerに登録する */
		atomic_init(&new_user->flags, 0);
		atomic_init(&new_user->worker, worker);
		new_user->next = worker->users;
		worker->users = new_user;
		user = new_user;
	}

	/* MLコードに復帰したときcurrent_userをNULLクリアする．
	 * MLコードにいる間は常にcurrent_userがNULLであるようにメンテナンス
	 * する．pthreadの場合はworker->current_userが唯一の
	 * ユーザーコンテキストを指し続けるので何もしなくてよい */
	if (!IS_PTHREAD(worker)) {
		user_tlv_set(current_user, NULL);
		worker->current_user = user;
	}

	/* sml_leaveで閉じたスタック範囲をsml_leaveを呼ぶ前の状態に戻す．*/
	assert(user->stack->top == frame_pointer);
	user->stack->top = NULL;
}

SML_PRIMITIVE void
sml_enter()
{
	sml_enter_internal(CALLER_FRAME_END_ADDRESS());
}

SML_PRIMITIVE void
sml_save()
{
	/* sml_allocを呼ぶ可能性のあるC関数をMLから呼び出すときに，
	 * GCコンテキストにいながらCコードを実行するために用いる．
	 * Cコードの実行中にルートセット列挙が行われる可能性があるため
	 * スタック範囲を閉じる．Cコードがsml_allocで確保したメモリの
	 * 生死は，Cコードが責任を持って管理しなければならない．この関数は
	 * そのような管理が行き届いている特別なCコードを呼び出すための
	 * 特別な関数である．*/
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;
	assert(IS_ACTIVE(load_relaxed(&worker->state)));
	assert(user->stack->top == NULL);
	user->stack->top = CALLER_FRAME_END_ADDRESS();
}

SML_PRIMITIVE void
sml_unsave()
{
	/* sml_saveと対になる．sml_allocを呼ぶ可能性のあるC関数からMLコード
	 * に復帰したときに呼び出される．sml_saveが閉じたスタック範囲を
	 * 再び開く．*/
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;
	assert(IS_ACTIVE(load_relaxed(&worker->state)));
	assert(user->stack->top == CALLER_FRAME_END_ADDRESS());
	user->stack->top = NULL;
}

/* for debug */
#ifndef NDEBUG
int
sml_saved()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = IS_PTHREAD(worker) ?
		worker->current_user : user_tlv_get(current_user);
	if (!user)
		user = worker->current_user;
	return user->stack->top != NULL;
}
#endif /* NDEBUG */

SML_PRIMITIVE void
sml_save_exn(void *obj)
{
	/* 例外がraiseされてからhandleされるまでの間にワーカーコンテキストを
	 * 離れなければならないときに，処理中の例外オブジェクトを生かして
	 * おくための関数である．
	 * このようなことが起こるのは，コールバック関数を超えてMLの例外を
	 * 伝播させるときである．コールバック関数の中で捕捉されない例外が
	 * 発生したとき，一旦Cコードに戻るため，コールバック関数のトップレベル
	 * コードのcleanupハンドラからsml_endが呼び出される．この例外が
	 * MLコードにhandleされsml_enterが呼び出されるまでの間に，C++コードが
	 * 設定したcleanupハンドラが起動され，C++コードが実行され，そこから
	 * MLのコールバック関数が実行される可能性がある．exn_objectはそのような
	 * MLコードの実行から処理中の例外オブジェクトを守るための領域である．
	 * なお，このように，ML例外を処理中にC++コードのcleanupハンドラから
	 * コールバックされたML関数がそのML関数内で捕捉されない例外を投げた
	 * 時は（つまりexn_objectがNULLでないときにさらにexn_objectに書き込
	 * もうとしたら），C++と同様に，プログラムを強制終了する．*/
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;
	if (user->exn_object)
		sml_fatal(0, "unhandled exception during exception handling");
	user->exn_object = obj;
}

SML_PRIMITIVE void *
sml_unsave_exn(void *p)
{
	/* sml_save_exnと対になる．コールバック関数を呼び出す可能性のある
	 * C関数の呼び出しには，sml_enterを呼び出すハンドラが必ず設定される．
	 * このハンドラは，C関数の呼び出しがhandleで囲われているかどうかに
	 * かかわらず，cleanupハンドラとして設定される．このハンドラは，
	 * sml_enterを呼び出しMLコードに復帰した後，処理対象の例外がMLの
	 * 例外ならば（C++の例外である可能性がある），sml_save_exnで保存した
	 * 例外オブジェクトを取り出す．引数pはこの条件を判定するフラグで，
	 * 処理対象の例外がMLのものならばnon-NULL，そうでなければNULLである．
	 * 従ってこの関数は，pがNULLならば何もしない．
	 */
	if (!p)
		return NULL;
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;
	void *ret = user->exn_object;
	assert(ret != NULL);
	user->exn_object = NULL;
	return ret;
}

enum sml_sync_phase
sml_current_phase()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);

	/* 現在のワーカーのフェーズを返す．「現在の」とは，「最も最後に
	 * 書き込まれた」という意味である．worker->stateにはワーカースレッドと
	 * コレクタスレッドの両方から書き込みが行われる．メモリコヒーレンシの
	 * おかげで，誰が書き込んだかにかかわらず，最後に書き込まれたフェーズが
	 * 必ず取り出される．なお，worker->stateをロードした直後に，フェーズが
	 * 進行している可能性があることに注意．例えば，この関数がSYNC1を読み
	 * 込んだとき，リターンする前にPRESYNC2に進行している可能性がある */
	return PHASE(load_relaxed(&worker->state));
}

SML_PRIMITIVE void
sml_start(void *memory)
{
	struct enter_worker e;
	struct sml_worker *worker;
	struct sml_user *user;
	struct frame_stack_range *range;
	void *frame_pointer = CALLER_FRAME_END_ADDRESS();
	enum sml_sync_phase phase;

	/* sml_startの第1引数は，sml_startを呼んだ関数のスタックフレームに
	 * 確保された3ポインタ分のメモリ領域である．
	 * このメモリ領域はframe_stack_rangeに使われる．*/
	if (sizeof(struct frame_stack_range) > sizeof(void*) * 3)
		sml_fatal(0, "assertion failed: "
			  "sizeof(struct frame_stack_range)"
			  " > sizeof(void*) * 3");
	range = memory;
	range->top = NULL;
	range->bottom = frame_pointer;

 retry:
	/* MLコードに入る．ワーカーコンテキストがなければ新しく作る．*/
	e = enter_worker();
	worker = e.worker;
//DBG("sml_start worker=%p", worker);

	/* sml_startが呼ばれるのは，新規のユーザースレッドが始まったときか，
	 * あるいは既存のユーザースレッド内でC関数からコールバックされたかの
	 * どちらかである．この区別はこのユーザースレッドがすでにユーザー
	 * コンテキストを持っているかどうかで判断できる．*/
	user = IS_PTHREAD(worker) ?
		worker->current_user : user_tlv_get(current_user);
	if (!user) {
		if (e.new_user) {
			user = e.new_user;
		} else {
			phase = PHASE(load_relaxed(&worker->state));
			user = sml_alloc_important(worker->allocator,
						   sizeof(struct sml_user),
						   phase);
			if (!user) {
				/* ユーザーコンテキストをGCなしで確保できない
				 * 状況ではユーザーを実行できない．そのため，
				 * このユーザーの実行を諦めざるを得ない．一旦
				 * MLコードを抜けて他のユーザースレッドにCPUを
				 * 譲る．*/
				leave_worker(worker);
				yield();
				goto retry;
			}
			OBJ_HEADER(user) = sizeof(struct sml_user);
		}

		atomic_init(&user->flags, 0);
		user->stack = range;
		user->stack->next = NULL;
		user->exn_object = NULL;

		/* workerに登録する．enter_workerを呼んだので，ワーカー
		 * コンテキストへの排他的アクセスをすでに持っている．*/
		atomic_init(&user->worker, worker);
		user->next = worker->users;
		worker->users = user;

		/* 「現在のワーカーコンテキスト」を表す変数には，
		 * worker->current_userとuser_tlv_get(current_user)の2つが
		 * ある．ここではMLコードにいるので前者のみセットする．
		 * ユーザースレッドローカル変数へのアクセスは遅いので，
		 * できるだけ減らしたい．特に，全てのスレッドが通過する
		 * sml_startやsml_endでは呼び出したくない．*/
		worker->current_user = user;
	} else {
		range->next = user->stack;
		user->stack = range;

		/* MLコードに復帰したときcurrent_userをNULLクリアする．
		 * 前述の通り，MLコードにいる間は常にcurrent_userが
		 * NULLであるようにメンテナンスする．*/
		if (!IS_PTHREAD(worker)) {
			worker->current_user = user;
			user_tlv_set(current_user, NULL);
		}
	}
//DBG("sml_start worker=%p user=%p", worker, user);
}

SML_PRIMITIVE void
sml_end()
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;
//DBG("sml_end worker=%p user=%p", worker, user);

	/* 先頭のスタック範囲を取り除く */
	user->stack = user->stack->next;

	/* sml_endが呼ばれるのはユーザースレッドが終了するときか，
	 * コールバック関数からのCへのリターンである．
	 * この区別はuser->stackを見れば分かる．
	 * 取り除いたスタック範囲が最後の1つだったならスレッド終了である． */
	if (!user->stack) {
		/* MLコードにいる間はcurrent_userはNULLであるように
		 * メンテナンスされているはずである．*/
		assert(IS_PTHREAD(worker) || !user_tlv_get(current_user));

		/* userをworker->usersから取り除く．ここで取り除いても良いが，
		 * リストを辿るコストがもったいないので，ここでは死亡フラグ
		 * だけ立てておく．userを取り除く処理はworker_sync2で
		 * 行われる．*/
		store_relaxed(&user->worker, NULL);

		/* これ以降，現在のユーザーコンテキストでMLコードを実行する
		 * ことはない．ここに到達した後，ユーザースレッドは死んで消える
		 * か，Cのコードを実行した後にMLコードに改めて復帰（sml_start）
		 * するかのどちらかである．前者の場合は現在のユーザーコンテ
		 * キストは二度と参照されない．後者の場合も，sml_startでは
		 * MLのユーザースレッドが新しく始まったと認識してユーザー
		 * コンテキストを作り直すので（なぜならcurrent_userがNULL
		 * だから），現在のユーザーコンテキストは二度と参照されない．
		 * このワーカーで次に走るMLコードは必ずsml_startかsml_enter
		 * で始まる．worker->current_userはsml_startかsml_enterで
		 * 参照されることなく上書きされるためここでNULLクリアする
		 * 必要はない．pthreadの場合，次にこのスレッドでsml_startが
		 * 呼び出された時にsml_startに新しいユーザーコンテキストを
		 * 作らせるため，ここでworker->current_userをNULLクリアする
		 * 必要がある．pthreadかどうかで分岐してNULLクリアするかどうか
		 * を決めるのもバカらしいので，ここで一律にworker->current_user
		 * をNULLクリアする．*/
		worker->current_user = NULL;
	} else {
		/* MLコードに復帰するときのために現在のコンテキストを
		 * ユーザースレッドローカル変数に保存する．
		 * MLコードにいないときworker->current_userは参照されない．
		 * このスレッドがpthreadのときはworker->current_userは
		 * 唯一のユーザーコンテキストを指し続けるので，ここでは
		 * 何もしなくて良い．*/
		if (!IS_PTHREAD(worker)) {
			assert(user_tlv_get(current_user) == NULL);
			user_tlv_set(current_user, user);
		}
	}

	/* MLコードから離れる．これ以降workerのロックは放棄されるので，
	 * workerとuserは他のスレッドからアクセスされる可能性があることに注意．
	 * 従ってleave_workerよりも後にworkerやuserに触れる処理をしては
	 * ならない．*/
	leave_worker(worker);
//DBG("sml_end worker=%p", worker);
}

static unsigned int
change_phase(struct sml_worker *workers,
	     enum sml_sync_phase old_phase, enum sml_sync_phase new_phase)
{
	struct sml_worker **i, *worker;
	unsigned int count = 0, old_state, flags;

	/* ワーカーコンテキストのリストを順に辿り，ワーカーコンテキストの
	 * フェーズをひとつずつ変更する．new_phaseがASYNCのとき，死亡条件
	 * （CANCELEDフラグが立っていて，ユーザーを持たず，かつリメンバード
	 * セットが空である）を満たすワーカーコンテキストはリストから取り
	 * 除かれる．ただし先頭のワーカーはworkers_availableから指されている
	 * ので取り除かない．
	 * ワーカーコンテキストの数は少ないので，並列化するコストをかけるよりも
	 * シーケンシャルにやったほうが早い，と仮定している．もしワーカーが
	 * たくさんいる場合は，このループを各ワーカーに分散，並列化することを
	 * 考えるべきである． */
	for (i = &workers; *i; ) {
		worker = *i;
		old_state = load_relaxed(&worker->state);

		/* 死亡条件を満たしたワーカーコンテキストをリストから取り除く．
		 * ワーカーコンテキストを安全に取り除けるのは，CANCELEDフラグが
		 * 立っており，worker->usersが空であり，リメンバーセットが空で
		 * あり，かつ所有するセグメントのコレクタービットマップがクリア
		 * な場合に限られる．GC開始時にworker->usersが空である場合，
		 * この条件が満たされる．
		 * CANCELEDフラグが立っているがworker->usersが空でない場合，
		 * それらのユーザーコンテキストに対応するユーザースレッドは
		 * 死んでいるか，他のワーカースレッドにスティールされたかの
		 * どちらかである．これらのユーザーコンテキストが全て削除される
		 * か他のワーカーコンテキストに移動するまでの間，ユーザー
		 * コンテキストは生き延びて，ハンドシェークに参加し続けなければ
		 * ならない．
		 * なお，workersの先頭はworkers_availableからも指されているため
		 * ここでは削除しない．先頭の要素が削除できる場合，削除する
		 * 代わりにDEADフラグを立てる．DEADフラグが立っている要素は
		 * global_phaseまたはregister_workerで削除される．*/
		flags = load_relaxed(&worker->flags);
		if ((flags & DEAD_FLAG) && i != &workers) {
//DBG("change_phase dead1 %p", worker);
			*i = worker->next;
			continue;
		} else if ((old_phase == ASYNC
			    && (flags & CANCELED_FLAG)
			    && worker->users == NULL)) {
//DBG("change_phase kill worker=%p allocator=%p", worker, worker->allocator);
			sml_heap_worker_kill(worker->allocator);
			store_relaxed(&worker->flags, flags | DEAD_FLAG);
			if (i != &workers) {
//DBG("change_phase dead2 %p", worker);
				*i = worker->next;
			} else {
				i = &worker->next;
			}
			continue;
		}

		/* フェーズ部分にXORをかけることで，INACTIVE_STATEに影響を
		 * 与えずにフェーズだけを置換する．全てのワーカーは同じ
		 * フェーズにいるはずである．
		 * change_phaseを呼ぶスレッドは，sml_check_flagの書き込みに
		 * ついて他の全てのスレッドと happened-before の関係にある．
		 * 従ってこのスレッドからは他のスレッドがsml_check_flag更新
		 * までに行った全ての書き込みが見えている．
		 * この状態を worker->state に release することで全フェーズ
		 * での全スレッドの操作を全スレッドに配る．*/
		assert(PHASE(load_relaxed(&worker->state)) == old_phase);
//DBG("change_phase worker=%p new_state=0x%02x", worker, load_relaxed(&worker->state) ^ old_phase ^ new_phase);
		fetch_xor(release, &worker->state, old_phase ^ new_phase);

		count++;
		i = &worker->next;
	}

	/* 今回のハンドシェークに参加するワーカーコンテキストのリストが
	 * 準備できたので，それをworkers_handshakeに書き出す．
	 * このリストに含まれるINACTIVEなワーカーコンテキストのアクションは，
	 * 誰か暇なワーカーが肩代わりする．help_inactive でNULLを書き込む時に
	 * 発生し得るABA問題を回避するため，下3ビットにフェーズを入れる．*/
	assert(((uintptr_t)worker & PHASE_MASK) == 0);
	assert((new_phase & ~PHASE_MASK) == 0);
	workers = PTROR(workers, new_phase);
	store_release(&workers_handshake, workers);

	return count;
}

static void
help_inactive(struct sml_worker *helper)
{
	struct sml_worker *old, *new, *worker, *workers;
	unsigned int old_state, new_state;
	enum sml_sync_phase stamp;

	/* この関数は，自分のアクションは完了したが他に完了していないワーカー
	 * コンテキストがあるときに呼ばれる．今回のハンドシェークに参加している
	 * ワーカーコンテキストのリスト（workers_handshake）のうち，
	 * INACTIVE(PRE...)をstateに持つもののアクションを肩代わりする */

	/* workers_handshakeの下3ビットは後述するABA問題を回避するための
	 * スタンプとしてフェーズが埋め込まれている */
	old = load_acquire(&workers_handshake);
	workers = PTRAND(old, ~(uintptr_t)PHASE_MASK);
	stamp = (uintptr_t)old & PHASE_MASK;

	for (worker = workers; worker; worker = worker->next) {
//DBG("help_inactive check worker=%p", worker);
		/* 死んでいるワーカーの手伝いをしない */
		if (load_relaxed(&worker->flags) & DEAD_FLAG)
			continue;
		/* 1と論理和を取るとPRE付きフェーズがPREなしフェーズに進む．
		 * 逆に~1と論理積を取るとPREなしフェーズがPRE付きフェーズに
		 * 戻る．PREなしフェーズの場合は何も起こらない．
		 * そうなるようにフェーズ定数が定義されている．
		 * この性質を利用して，PRE付きフェーズでINACTIVEなステートを
		 * 持つワーカーのみをworkers_handshakeに残す．*/
		old_state = load_relaxed(&worker->state);
		if (old_state != INACTIVE(old_state & ~1)) {
//DBG("help_inactive worker=%p old_state %02x != %02x", worker, old_state, INACTIVE(old_state & ~1));
			continue;
}
		/* 肩代わり対象のワーカーコンテキストをworkers_handshakeから
		 * 取り外す．あくまで手助けなので，取り出しに失敗したら
		 * リトライせずに諦める */
		assert(((uintptr_t)worker->next & PHASE_MASK) == 0);
		new = PTROR(worker->next, stamp);
		if (!cmpswap_weak_relaxed(&workers_handshake, &old, new)) {
//DBG("help_inactive worker=%p help fail", worker);
			return;
}
		/* 取り出したワーカーコンテキストが本当に手助けを必要として
		 * いるかチェックしつつ，PREありフェーズからPREなしフェーズに
		 * 進め，ロックを確保する．対象のワーカーコンテキストはすでに
		 * workers_handshakeから取り外されているので，もし手助けが
		 * 必要ならここで確実に手助けしなければならない．そのため，
		 * ロックが取れるなら確実に取らないといけないので，このCASは
		 * weakであってはならない．逆に手助けが必要でなければ，
		 * 特に何もしなくてよい．
		 * このacquireに対するreleaseはleave_workerにある．*/
		new_state = ACTIVE(PHASE(old_state) | 1) | HELPER_STATE;
		if (!cmpswap_acquire(&worker->state, &old_state, new_state))
			return;
		for (;;) {
//DBG("help_inactive worker=%p old_state=0x%02x", worker, old_state);
			switch(PHASE(old_state)) {
			case PREASYNC:
				worker_async(worker);
				break;
			case PRESYNC1:
				worker_sync1(worker, 0);
				break;
			case PRESYNC2:
				worker_sync2(worker, 0);
				break;
			case PREMARK:
				worker_mark(worker, 0);
				break;
			default:
				sml_fatal(0, "unexpected state 0x%02x",
						old_state);
			}
			/* workerはアクションを行ったので，自分を含む誰かが
			 * workerのフェーズをPREなしフェーズからPREありフェーズ
			 * に進める可能性がある．もしこのコメントがある位置で
			 * PREありフェーズに進行した場合，シグナルを受理し
			 * アクションを実行する責任はこのヘルパにある．
			 * leave_workerとは異なり，ヘルパはアクションを実行
			 * している間はACTIVEフラグを立てていなければならない．
			 * 従って安全にACTIVEフラグをオフしてヘルパ作業を終え
			 * られるのは，worker->stateがnew_stateのまま変化が
			 * ないときに限られる．そうでなければACTIVEのままもう
			 * 一度アクションを実行する必要がある．ヘルパがワーカー
			 * である場合，ヘルパ自身もシグナルに応答しなければ
			 * ならないため，このループを回るのは高々2回のはず
			 * である．*/
			old_state = new_state;
			new_state ^= INACTIVE_STATE | HELPER_STATE;
			if (cmpswap_release(&worker->state,
					    &old_state, new_state))
				break;
//DBG("help_inactive retry worker=%p", worker);
			new_state = old_state | 1;
			store_relaxed(&worker->state, new_state);
		}
		return;
	}

	/* 全てのワーカーコンテキストについてヘルプの必要がない場合，
	 * workers_handshakeをNULLでクリアする．ただし，この時点で全体が
	 * 次のフェーズに進行している可能性があることに注意が必要である．
	 * NULLクリアできるのは，load_acquire(&workers_handshake) してから
	 * この時点までフェーズが進行していない場合に限られる．フェーズが
	 * 進行しているにもかかわらず workers_handshake が同じ値の場合，
	 * ABA問題が発生する．この問題を回避するために，workers_handshakeの
	 * 下3ビットにタイムスタンプとしてフェーズを埋め込む．
	 * ヘルパがワーカーの場合，ヘルパ自身もシグナルに応答しなければ
	 * フェーズが進行することはないので，フェーズをタイムスタンプとして
	 * CASを行えば，ABAを回避できる．*/
	if (workers && helper) {
//DBG("help_inactive NULL");
		cmpswap_weak_relaxed(&workers_handshake, &old,
				     PTROR(NULL, stamp));
	}
}

unsigned long
sml_gc(int greedy)
{
	struct sml_worker *workers;
	unsigned int count;
	unsigned long gc;

	/* まだGCが始まっていなければGCを開始する．すでにGCが始まっている
	 * のであれば終了時のGCカウントを返す．*/
	gc = load_relaxed(&gc_count);
	if ((gc & 1) != 0)
		return gc + 1;
	gc = fetch_or(relaxed, &gc_count, 1);
	if ((gc & 1) != 0)
		return gc + 1;

	/* GC開始のトリガを引いた人が，全ワーカーのPRESYNC1への変更を行う．*/
#ifdef GCTIME
	sml_timer_now(gctime.sync1_start);
#endif
//DBG("SYNC1");
	workers = global_phase(SYNC1);
	count = change_phase(workers, ASYNC, PRESYNC1);
	/* countをsml_check_flagに加える．コピーではないことに注意．
	 * すでにワーカーのフェーズはPRESYNC1になっているので，
	 * ここでsml_check_flagを増やす前にsml_check_flagが
	 * 負になっている可能性がある．*/
	fetch_add(relaxed, &sml_check_flag, count);

	if (greedy) {
		/* 自分のsync1アクションはここでやってしまう */
		struct sml_worker *worker = worker_tlv_get(current_worker);
		assert(load_relaxed(&worker->state) == ACTIVE(PRESYNC1));
		store_relaxed(&worker->state, ACTIVE(SYNC1));
		worker_sync1(worker, greedy);
	}

	return gc + 2;
}

unsigned long
sml_wait_gc(void *frame_pointer)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user = worker->current_user;

	assert(IS_ACTIVE(load_relaxed(&worker->state)));

	void *orig = user->stack->top;
	if (!orig)
		user->stack->top = frame_pointer;

	unsigned long gc = sml_gc(1);

	if (!orig)
		user->stack->top = orig;

	/* GCカウントがgc以上になるまで（少なくとも1回のGCが終わるまで）待つ */
	while (load_relaxed(&gc_count) < gc)
		sml_check_internal(frame_pointer);

	return gc;
}

static void
worker_sync1(struct sml_worker *worker, int greedy)
{
	struct sml_worker *workers;
	unsigned int count;

	/* カウンタをデクリメントする．
	 * sml_check_flagは負になる可能性があることに注意．
	 * コレクタがsml_check_flagに応答すべきワーカー数を加える前に
	 * 応答すべきワーカーのフェーズは変更されているので，
	 * sml_check_flagが正になる前にこの減算が実行される可能性がある．
	 * カウンタがちょうど0になったときが，全てのワーカーから応答が
	 * あったときである．
	 * このカウンタへのアトミックアクセスのrelease sequenceを通じて，
	 * 全スレッドのメモリ書き込みをカウンタを0にしたワーカーに集約する．
	 * カウンタを0にしたスレッドはこのrelease sequenceをacquireする．
	 * これによって他のスレッドがカウンタ書き込み前に行ったメモリ操作が
	 * カウンタを0にしたスレッドから見えるようになる */
	if (fetch_sub(acq_rel, &sml_check_flag, 1) == 1) {
		/* 全てのワーカーが応答したとき，最後に応答したワーカーが
		 * 全体を次のフェーズに進める．*/
		/* 最後にSYNC1に応答したワーカーがSYNC2でグローバル変数を
		 * 列挙する */
		fetch_or(relaxed, &worker->flags, GLOBALENUM_FLAG);
#ifdef GCTIME
		sml_timer_now(gctime.sync2_start);
#endif
//DBG("SYNC2");
		workers = global_phase(SYNC2);
		count = change_phase(workers, SYNC1, PRESYNC2);
		/* この関数がleave_workerから呼ばれていてかつここに到達した
		 * とき，他のスレッドがヘルパとしてworkerにアクセスしている
		 * 可能性がある．greedyが0ならばここ以降workerにアクセスしては
		 * ならない */
		/* countをsml_check_flagに加える．コピーではないことに注意．
		 * すでにワーカーのフェーズはPRESYNC2になっているので，
		 * ここでsml_check_flagを増やす前にsml_check_flagが
		 * 負になっている可能性がある．*/
		fetch_add(relaxed, &sml_check_flag, count);

		if (greedy) {
			/* 自分のsync2アクションはここでやってしまう */
			assert(load_relaxed(&worker->state)
			       == ACTIVE(PRESYNC2));
			store_relaxed(&worker->state, ACTIVE(SYNC2));
			worker_sync2(worker, greedy);
		}
	}
}

static void
worker_sync2(struct sml_worker *worker, int greedy)
{
	struct sml_user **i, *user, *pending;
	struct sml_worker *workers;
	unsigned int count;
#ifdef GCHIST
	sml_timer_t t1, t2;
	sml_time_t t;
	sml_timer_now(t1);
#endif

	i = &worker->users;
	do {
		pending = NULL;
		while (*i) {
			user = *i;

			/* 他のワーカーがuserのルートセット列挙をしている
			 * 可能性を排除するため，userのBUSY_FLAGロックを取る．
			 * ロックが取れないとき，他のワーカースレッドが
			 * sml_enterでuserのルートセット列挙をしている
			 * 最中である．それが終わるまで待つ */
			if (!acquire_bit(&user->flags, BUSY_FLAG)) {
				/* このuserのルートセット列挙は後回しにして，
				 * 先に後続のユーザーに対して仕事をする．
				 * 後回しにしたことを覚えるために，
				 * userをworker->usersからpendingに移動する．
				 * もしこのワーカーにはロックが取れないユーザー
				 * しか存在しなかったとしたら，このポインタ
				 * 繋ぎ変えコードがビジーにループし続けること
				 * になる．ビジーループに陥ったときここで他の
				 * 意味のある仕事ができると効率が良さそうだが，
				 * それは難しそうである．
				 * この関数を実行するスレッドはワーカー自身か
				 * ヘルパーのどちらかのはずで，どちらかによって
				 * 「他の意味のある仕事」は異なる．
				 * また，今はルートセット列挙の途中である．
				 * たとえこの関数を実行しているのがワーカー自身
				 * であったとしても，ルートセット列挙処理と，
				 * （別の）ユーザースレッドによるメモリ確保や
				 * ルートセット変更がインターリーブするのは，
				 * いかにもよろしくなさそうである
				 * （ちゃんと考えればいけるかも）．
				 * 従って，ここではビジーループせざるを得ない．
				 * そもそもこの分岐に到達するのはワークスティー
				 * ルとルートセット列挙が同時に起こった場合だけ
				 * なので，ここに来る可能性は低いと信じたい */
				*i = user->next;
				user->next = pending;
				pending = user;
				continue;
			}

			/* userはもはやこのワーカーに属していない
			 * （ワークスティールされたか死んだ）ならば，
			 * userのルートセット列挙をする責任はこのワーカーには
			 * 無いので，リストからユーザーを削除する．
			 * このチェックはここで行われなければならない．
			 * sml_enterやcancel_userでは，ロックの内側で
			 * user->workerを書き換えることで，このワーカーによる
			 * ルートセット列挙を抑止する．*/
			if (load_relaxed(&user->worker) != worker) {
//DBG("sml_heap_worker_sync2 dead worker=%p user=%p", worker, user);
				*i = user->next;
				continue;
			}

//DBG("sml_heap_user_sync2 worker=%p user=%p", worker, user);
			sml_heap_user_sync2(user, worker->allocator);

			/* ロック解除．user->flagsはBUSY_FLAGしか使わないので
			 * シンプルに0をストアすれば良い．*/
			store_release(&user->flags, 0);

			i = &user->next;
		}

		/* 後回しにしたユーザーはworker->usersからpendingに移動して
		 * いるので，それらをworker->usersの末尾に追加して戻す．*/
		*i = pending;
	} while (pending);

//DBG("sml_heap_worker_sync2 worker=%p alloc=%p", worker, worker->allocator);
	sml_heap_worker_sync2(worker, worker->allocator);

	/* グローバル変数を列挙する責任を持っているならば，
	 * グローバル変数の列挙を行う．この分だけこのワーカースレッドの
	 * 負担が増えてしまうが仕方がない */
	if (load_relaxed(&worker->flags) & GLOBALENUM_FLAG) {
		sml_heap_global_sync2(worker->allocator);
		fetch_and(relaxed, &worker->flags, ~GLOBALENUM_FLAG);
	}

#ifdef GCHIST
	sml_timer_now(t2);
	sml_timer_dif(t1, t2, t);
	DBG("  - {count: %u, sync2: "TIMEFMT"}", load_relaxed(&gc_count)/2, TIMEARG(t));
#endif

	/* カウンタをデクリメントする．
	 * sml_check_flagは負になる可能性があることに注意．
	 * コレクタがsml_check_flagに応答すべきワーカー数を加える前に
	 * 応答すべきワーカーのフェーズは変更されているので，
	 * sml_check_flagが正になる前にこの減算が実行される可能性がある．
	 * カウンタがちょうど0になったときが，全てのワーカーから応答が
	 * あったときである．
	 * このカウンタへのアトミックアクセスのrelease sequenceを通じて，
	 * 全スレッドのメモリ書き込みをカウンタを0にしたワーカーに集約する．
	 * カウンタを0にしたスレッドはこのrelease sequenceをacquireする．
	 * これによって他のスレッドがカウンタ書き込み前に行ったメモリ操作が
	 * カウンタを0にしたスレッドから見えるようになる */
	if (fetch_sub(acq_rel, &sml_check_flag, 1) == 1) {
		/* 全てのワーカーが応答したとき，最後に応答したワーカーが
		 * 全体を次のフェーズに進める．*/
#ifdef GCTIME
		sml_timer_now(gctime.mark_start);
#endif
//DBG("MARK");
		workers = global_phase(MARK);
		count = change_phase(workers, SYNC2, PREMARK);
		/* この関数がleave_workerから呼ばれていてかつここに到達した
		 * とき，他のスレッドがヘルパとしてworkerにアクセスしている
		 * 可能性がある．greedyが0ならばここ以降workerにアクセスしては
		 * ならない */
		/* countをsml_check_flagに加える．コピーではないことに注意．
		 * すでにワーカーのフェーズはPREMARKになっているので，
		 * ここでsml_check_flagを増やす前にsml_check_flagが
		 * 負になっている可能性がある．*/
		fetch_add(relaxed, &sml_check_flag, count);

		if (greedy) {
			/* 自分のmarkアクションはここでやってしまう */
			assert(load_relaxed(&worker->state) == ACTIVE(PREMARK));
			store_relaxed(&worker->state, ACTIVE(MARK));
			worker_mark(worker, greedy);
		}
	}
}

static void
worker_mark(struct sml_worker *worker, int greedy)
{
	struct sml_worker *workers;
	unsigned int count;

 retry:
#ifdef GCHIST
	(void)0;
	sml_timer_t t1, t2;
	sml_time_t t;
	sml_timer_now(t1);
#endif

	sml_heap_worker_mark(worker->allocator);

#ifdef GCHIST
	sml_timer_now(t2);
	sml_timer_dif(t1, t2, t);
	DBG("  - {count: %u, mark: "TIMEFMT"}", load_relaxed(&gc_count)/2, TIMEARG(t));
#endif

	/* カウンタをデクリメントする．
	 * sml_check_flagは負になる可能性があることに注意．
	 * コレクタがsml_check_flagに応答すべきワーカー数を加える前に
	 * 応答すべきワーカーのフェーズは変更されているので，
	 * sml_check_flagが正になる前にこの減算が実行される可能性がある．
	 * カウンタがちょうど0になったときが，全てのワーカーから応答が
	 * あったときである．
	 * このカウンタへのアトミックアクセスのrelease sequenceを通じて，
	 * 全スレッドのメモリ書き込みをカウンタを0にしたワーカーに集約する．
	 * カウンタを0にしたスレッドはこのrelease sequenceをacquireする．
	 * これによって他のスレッドがカウンタ書き込み前に行ったメモリ操作が
	 * カウンタを0にしたスレッドから見えるようになる */
	if (fetch_sub(acq_rel, &sml_check_flag, 1) == 1) {
		/* 全てのワーカーが応答したとき，最後に応答したワーカーが
		 * トレース終了をチェックする．*/
		if (sml_heap_mark_finish()) {
			/* トレースが終了したとき，最後に応答したワーカーが
			 * 全体を次のフェーズに進める．*/
			sml_run_finalizer();
//DBG("sml_heap_global_before_async worker=%p", worker);
			sml_heap_global_before_async();
#ifdef GCTIME
			sml_timer_now(gctime.async_start);
#endif
//DBG("ASYNC");
			workers = global_phase(ASYNC);
			count = change_phase(workers, MARK, PREASYNC);
			/* この関数がleave_workerから呼ばれていてかつここに
			 * 到達したとき，他のスレッドがヘルパとしてworkerに
			 * アクセスしている可能性がある．greedyが0ならばここ
			 * 以降workerにアクセスしてはならない */
			/* countをsml_check_flagに加える．コピーではないことに
			 * 注意．すでにワーカーのフェーズはPREASYNCになっている
			 * ので，ここでsml_check_flagを増やす前にsml_check_flag
			 * が負になっている可能性がある．*/
			fetch_add(relaxed, &sml_check_flag, count);

			if (greedy) {
				/* 自分のasyncアクションはここでやってしまう */
				assert(load_relaxed(&worker->state)
				       == ACTIVE(PREASYNC));
				store_relaxed(&worker->state, ACTIVE(ASYNC));
				worker_async(worker);
			}
		} else {
			/* トレースがまだ終了していないとき，MARKフェーズを
			 * 繰り返す．*/
#ifdef GCTIME
			gctime.mark_retry++;
#endif
#ifdef GCHIST
			DBG("  - mark_retry: 0");
#endif
			workers = global_phase(MARK);
			count = change_phase(workers, MARK, PREMARK);
			/* この関数がleave_workerから呼ばれていてかつここに
			 * 到達したとき，他のスレッドがヘルパとしてworkerに
			 * アクセスしている可能性がある．greedyが0ならばここ
			 * 以降workerにアクセスしてはならない */
			/* countをsml_check_flagに加える．
			 * コピーではないことに注意．
			 * すでにワーカーのフェーズはPREMARKになっているので，
			 * ここでsml_check_flagを増やす前にsml_check_flagが
			 * 負になっている可能性がある．*/
			fetch_add(relaxed, &sml_check_flag, count);

			if (greedy) {
				/* 自分のmarkアクションはここでやってしまう */
				assert(load_relaxed(&worker->state)
				       == ACTIVE(PREMARK));
				store_relaxed(&worker->state, ACTIVE(MARK));
				goto retry;
			}
		}
	}
}

static void
worker_async(struct sml_worker *worker)
{
//DBG("sml_heap_worker_async worker=%p", worker);
	sml_heap_worker_async(worker->allocator);

	/* カウンタをデクリメントする．
	 * sml_check_flagは負になる可能性があることに注意．
	 * コレクタがsml_check_flagに応答すべきワーカー数を加える前に
	 * 応答すべきワーカーのフェーズは変更されているので，
	 * sml_check_flagが正になる前にこの減算が実行される可能性がある．
	 * カウンタがちょうど0になったときが，全てのワーカーから応答が
	 * あったときである．
	 * このカウンタへのアトミックアクセスのrelease sequenceを通じて，
	 * 全スレッドのメモリ書き込みをカウンタを0にしたワーカーに集約する．
	 * カウンタを0にしたスレッドはこのrelease sequenceをacquireする．
	 * これによって他のスレッドがカウンタ書き込み前に行ったメモリ操作が
	 * カウンタを0にしたスレッドから見えるようになる */
	if (fetch_sub(acq_rel, &sml_check_flag, 1) == 1) {
		/* 最後に応答したワーカーがセグメントプールの回収を行う */
//DBG("sml_heap_global_async worker=%p", worker);
		sml_heap_global_async();
		/* GCを終了する．*/
#ifdef GCTIME
		sml_timer_t reclaim_end;
		sml_timer_now(reclaim_end);
		sml_timer_accum(gctime.sync1_start, gctime.sync2_start,
				gctime.sync1);
		sml_timer_accum(gctime.sync2_start, gctime.mark_start,
				gctime.sync2);
		sml_timer_accum(gctime.mark_start, gctime.async_start,
				gctime.mark);
		sml_timer_accum(gctime.async_start, reclaim_end,
				gctime.reclaim);
#endif
		assert(load_relaxed(&gc_count) & 1);
		fetch_add(relaxed, &gc_count, 1);
	}
}

sml_check_hook_fn
sml_set_check_hook(sml_check_hook_fn hook)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	sml_check_hook_fn old = worker->check_hook;
	worker->check_hook = hook;
	return old;
}

struct check_hook_cleanup_arg {
	void *fp, *orig, **top;
};

static void
check_hook_cleanup(void *arg, void *u, void *e)
{
	struct check_hook_cleanup_arg *a = arg;
	sml_enter_internal(a->fp);
	*a->top = a->orig;
	sml_unsave_exn(e);
}

void
sml_check_internal(void *frame_pointer)
{
	struct sml_worker *worker = worker_tlv_get(current_worker);
	struct sml_user *user;
	unsigned int state;
	void *orig;

	/* change_phaseはworker->stateを書き換える時releaseすることで，
	 * 全フェーズで全スレッドが行った書き込みが全スレッドから見えるように
	 * している．これに対応して，ここではworker->stateをacquireする．*/
	state = load_acquire(&worker->state);
	assert(IS_ACTIVE(state));

	switch(state) {
	case ACTIVE(PRESYNC1):
		store_relaxed(&worker->state, ACTIVE(SYNC1));
		user = worker->current_user;
		/* sml_checkは，MLコードから直接呼び出されるか，sml_allocから
		 * 呼び出されるかのどちらかである．後者の場合，sml_allocの前に
		 * sml_saveが呼ばれている場合（sml_str_newをMLから呼び出す場合
		 * など）とそうでない場合がある．従って，スタック範囲がまだ
		 * 閉じられていない（user->stack->topがNULL）可能性がある．
		 * スタック範囲が閉じられていないとworker_sync2でルートセット
		 * 列挙ができないので，もし閉じられていないならばここで
		 * 一時的に閉じる．
		 * worker_sync1はgreedyを1にしているのでworker_sync2を呼ぶ
		 * 可能性がある．worker_sync2はスタック範囲が閉じられている
		 * ことを要求する．*/
		orig = user->stack->top;
		if (!orig)
			user->stack->top = frame_pointer;
		worker_sync1(worker, 1);
		if (!orig)
			user->stack->top = orig;
		break;
	case ACTIVE(PRESYNC2):
		store_relaxed(&worker->state, ACTIVE(SYNC2));
		user = worker->current_user;
		/* sml_checkは，MLコードから直接呼び出されるか，sml_allocから
		 * 呼び出されるかのどちらかである．後者の場合，sml_allocの前に
		 * sml_saveが呼ばれている場合（sml_str_newをMLから呼び出す場合
		 * など）とそうでない場合がある．従って，スタック範囲がまだ
		 * 閉じられていない（user->stack->topがNULL）可能性がある．
		 * スタック範囲が閉じられていないとworker_sync2でルートセット
		 * 列挙ができないので，もし閉じられていないならばここで
		 * 一時的に閉じる．*/
		orig = user->stack->top;
		if (!orig)
			user->stack->top = frame_pointer;
		worker_sync2(worker, 1);
		if (!orig)
			user->stack->top = orig;
		break;
	case ACTIVE(PREMARK):
		store_relaxed(&worker->state, ACTIVE(MARK));
		worker_mark(worker, 1);
		break;
	case ACTIVE(PREASYNC):
		store_relaxed(&worker->state, ACTIVE(ASYNC));
		worker_async(worker);
		break;
	default:
		assert(IS_ACTIVE(state));
		/* 自分のアクションは終わったがまだアクションを終えていない
		 * ワーカーがいるときここに到達する．INACTIVEなワーカーの
		 * アクションを肩代わりする．*/
		help_inactive(worker);
		break;
	}

	if (worker->check_hook) {
		struct check_hook_cleanup_arg a;
		void *hook = worker->check_hook;
		/* worker->check_hookはMLのコールバック関数であっても良い．
		 * check_hook実行中にcheck_hookを呼び出しループすることが
		 * ないように，check_hookはワンショットとする．*/
		worker->check_hook = NULL;
		/* check_hookを呼ぶ前にsml_leaveしなければならない．
		 * sml_checkは，MLコードから直接呼び出されるか，sml_allocから
		 * 呼び出されるかのどちらかである．後者の場合，sml_allocの前に
		 * sml_saveが呼ばれている場合（sml_str_newをMLから呼び出す場合
		 * など）とそうでない場合がある．従って，スタック範囲がすでに
		 * 閉じられている（user->stack->topがNULLでない）可能性がある．
		 * 閉じられているならばそれを尊重し，閉じられていないならば
		 * frame_pointerで閉じるようにsml_leaveを仕向ける．同様に，
		 * sml_enterの後はuser->stack->topを元に戻すように整える．
		 */
		user = worker->current_user;
		a.top = &user->stack->top;
		a.orig = *a.top;
		a.fp = a.orig ? a.orig : frame_pointer;
		DEBUG(user->stack->top = NULL);
		sml_leave_internal(a.fp);
		sml_call_with_cleanup(hook, check_hook_cleanup, &a);
	}
}

SML_PRIMITIVE void
sml_check(unsigned int check ATTR_UNUSED)
{
	assert(worker_tlv_get(current_worker)->current_user->stack->top
	       == NULL);
	sml_check_internal(CALLER_FRAME_END_ADDRESS());
}

static void *
frame_enum_ptr(void *frame_end, void (*trace)(void **, void *), void *data)
{
	void *codeaddr = FRAME_CODE_ADDRESS(frame_end);
	void *frame_begin, **slot;
	const struct sml_frame_layout *layout = sml_lookup_frametable(codeaddr);
	uint16_t num_roots, i;

	/* assume that the stack grows downwards. */
	frame_begin = (void**)frame_end + layout->frame_size;
	num_roots = layout->num_roots;

	for (i = 0; i < num_roots; i++) {
		slot = (void**)frame_end + layout->root_offsets[i];
		if (*slot)
			trace(slot, data);
	}

	return NEXT_FRAME(frame_begin);
}

void
sml_stack_enum_ptr(struct sml_user *user,
		   void (*trace)(void **, void *), void *data)
{
	void *fp, *next;
	struct frame_stack_range *range;

	/* userはBUSY_STATEがセット（ロックが保持）されており，かつ
	 * user->stackはNULLではないはずである（user->stackがNULLに
	 * なるのはsml_endで終了したユーザーのみ）．*/
	assert(user != NULL);
	assert(load_relaxed(&user->flags) & BUSY_FLAG);
	assert(user->stack != NULL);

	if (user->exn_object)
		trace(&user->exn_object, data);

	for (range = user->stack; range; range = range->next) {
		/* スタック範囲は全て閉じられているはず */
		assert(range->top != NULL && range->bottom != NULL);
		/* スタック範囲には必ず1つのフレームが含まれる */
		fp = range->top;
		for (;;) {
			next = frame_enum_ptr(fp, trace, data);
			if (fp == range->bottom)
				break;
			fp = next;
		}
	}
}

void
sml_exit(int status)
{
	struct sml_worker *current, *workers, *worker, *old;
	unsigned int old_state;

	/* 現在のワーカーはNULLかもしれない．
	 * この関数はcurrentがNULLでも動くように書いてある．*/
	current = worker_tlv_get(current_worker);

	/* 新しいワーカーの登録を禁止する．*/
	old = load_acquire(&workers_available);
	do {
		/* workers_availableの下3ビットを0にする */
		workers = PTRAND(old, ~(uintptr_t)PHASE_MASK);
	} while (!cmpswap_weak_acq_rel(&workers_available, &old, workers));

	/* 他のワーカーのロックをすべて取る．*/
	for (worker = workers; worker; worker = worker->next) {
		if (worker == current)
			continue;
		old_state = fetch_and(relaxed, &worker->state, ~INACTIVE_STATE);
		if (IS_ACTIVE(old_state)) {
			/* ロックの取得に失敗した場合はただちに終了 */
			goto exit;
		}
	}

	/* これで，他のワーカーは全てMLコードを実行していない状態になった．
	 * 自分一人しか動いていないので，MLのランタイムが管理する全ての
	 * グローバルな資源に安全にアクセスできる．この状態に持って行けた
	 * ときのみ後片付けを行う．そうでなければ強制終了する．*/
	sml_finish();

 exit:
#ifdef GCTIME
	(void)0;
	sml_timer_t exec_end;
	sml_time_t exectime;
	sml_timer_now(exec_end);
	sml_timer_dif(gctime.exec_start, exec_end, exectime);
	sml_notice(" exectime: "TIMEFMT" #sec", TIMEARG(exectime));
	sml_notice(" gccount: %lu", load_relaxed(&gc_count) / 2);
	sml_notice(" sync1: "TIMEFMT" #sec", TIMEARG(gctime.sync1));
	sml_notice(" sync2: "TIMEFMT" #sec", TIMEARG(gctime.sync2));
	sml_notice(" mark: "TIMEFMT" #sec", TIMEARG(gctime.mark));
	sml_notice(" async: "TIMEFMT" #sec", TIMEARG(gctime.reclaim));
	sml_notice(" mark_retry: %u", gctime.mark_retry);
#endif
#ifdef GCHIST
	sml_notice(" hist:");
	DBGdump(NULL);
#endif
	exit(status);
}
