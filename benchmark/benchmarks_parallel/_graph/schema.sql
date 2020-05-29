create table bench (
 bench text,
 lang text,
 impl text,
 size int,
 cutoff int,
 result int,
 cores int,
 iter int,
 time float,
 maxrss int
);

create view avg as
 select bench,
        lang,
        impl,
        size,
        cutoff,
        cores,
        avg(time) as time,
        min(time) as min_time,
        max(time) as max_time
 from bench
 where iter <> 1
 group by bench, lang, impl, size, cutoff, cores
 order by bench, lang, impl, size, cutoff, cores;

create view scale as
 select bench,
        lang,
        impl,
        size,
        cutoff,
        cores,
        t1/time as time,
        t1/min_time as min_time,
        t1/max_time as max_time
 from avg
 natural join (select bench, lang, impl, size, cutoff, time as t1
               from avg
               where cores = 1);

create view rss as
 select bench,
        lang,
        impl,
        size,
        cutoff,
        cores,
        maxrss
 from bench
 where iter = 1;




