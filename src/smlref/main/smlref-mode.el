(require 'json)

(defvar smlref-command
  "/home/ohori/share/HG/smlsharp/smlsharp/src/smlref/main/SMLRef")
(defvar smlref-word-char "a-zA-Z_'0-9")
(defvar smlref-window-fraction 0.3)
(defconst smlref-config-cmd (cons 'cmd "config"))
(defconst smlref-finddef-cmd (cons 'cmd "findDef"))
(defconst smlref-findref-cmd (cons 'cmd "findRef"))
;;;(defvar findDefEchoCmd (cons 'cmd "findDefEcho"))

(defvar smlref-system-name nil)
(defvar smlref-base-dir nil)
(defvar smlref-version nil)
(defvar smlref-root-file nil)

(defun smlref-goto-char (pos)
  (let ((old enable-multibyte-characters))
    (set-buffer-multibyte nil)
    (unwind-protect
        (goto-char pos)
      (set-buffer-multibyte old))))

(defun smlref-assoc (att alist)
  (cdr (assoc att alist)))

(defun smlref-display-filebuf-pos (fileBuf pos)
  (display-buffer-at-bottom
   fileBuf
   (list (cons 'window-height smlref-window-fraction)))
  (switch-to-buffer-other-window fileBuf)
  (smlref-goto-char (+ pos 1)))

;;;(defun displayFilePos (filePath pos)
;;;  (setq fileBuf (find-file-noselect filePath))
;;;  (smlref-display-filebuf-pos fileBuf pos)
;;;)

(defun smlref-get-pos-filepath ()
  (save-excursion
    (beginning-of-line)
    (let* ((pos-start (point))
           (pos-end (progn (search-forward ":") (- (point) 1)))
           (path-start (+ pos-end 1))
           (path-end (progn (end-of-line) (point)))
           (pos (string-to-number
                 (buffer-substring-no-properties pos-start pos-end)))
           (path (buffer-substring-no-properties path-start path-end)))
      (cons pos path))))

(defun smlref-open-ref-point ()
  (interactive)
  (let* ((pos-path (smlref-get-pos-filepath))
         (pos (car pos-path))
         (path (cdr pos-path))
         (filepath (concat (file-name-as-directory smlref-base-dir) path))
         (filebuf (find-file-noselect filepath)))
    (smlref-display-filebuf-pos filebuf pos)))

;;;(defun getSMLWord ()
;;;  (set-buffer-multibyte nil)
;;;  (let
;;;      ((word-end (progn (skip-chars-forward sml-word-char) (point)))
;;;       (word-start (progn (skip-chars-backward sml-word-char) (point))))
;;;    (buffer-substring-no-properties word-start word-end))
;;;  )

(defun smlref-get-sml-word-point ()
  (save-excursion
    (skip-chars-backward smlref-word-char)
    (let ((old enable-multibyte-characters))
      (set-buffer-multibyte nil)
      (unwind-protect
          (point)
        (set-buffer-multibyte old)))))

(defun smlref-execute-command (alist)
  (with-current-buffer (get-buffer-create "*sml#ref*")
    (goto-char (point-max))
    (let ((json (json-encode-list alist)))
      (insert (prin1-to-string alist) "\n")
      (insert json "\n")
      (let* ((result
              (with-output-to-string
                (call-process smlref-command nil standard-output nil json)))
             (res (ignore-errors (json-read-from-string result))))
        (insert result "\n")
        (insert (prin1-to-string res) "\n")
        res))))

(defun smlref-get-file-info ()
  (list (cons 'path (buffer-file-name (current-buffer)))
        (cons 'pos (- (smlref-get-sml-word-point) 1))))

;;;(defun formatAttrib (cell)
;;;  (let* ((l (car cell))
;;;	 (v (cdr cell))
;;;	 (vs (cond
;;;	      ((integerp v) (int-to-string v))
;;;	      ((stringp v) v)
;;;	      (t "?"))))
;;;    (concat (symbol-name l) " : " vs ))
;;;  )

;;;(defun formatAlist (alist)
;;;  (mapconcat 'formatAttrib alist "\n")
;;;  )

(defun smlref-set-config ()
  (with-current-buffer (get-buffer-create "*sml#ref*")
    (goto-char (point-max))
    (insert "setConfig:\n"))
  (let ((res (smlref-execute-command (list smlref-config-cmd))))
    (setq smlref-version (smlref-assoc 'version res))
    (setq smlref-system-name (smlref-assoc 'systemName res))
    (setq smlref-base-dir (smlref-assoc 'baseDir res))
    (setq smlref-root-file (smlref-assoc 'rootFile res))))

(defun smlref-insert-file-pos (filePathPos)
  (let ((path (smlref-assoc 'path filePathPos))
        (pos (smlref-assoc 'pos filePathPos)))
    (insert (number-to-string pos) ":" path "\n")))

(defun smlref-find-def ()
  (interactive)
  (with-current-buffer (get-buffer-create "*sml#ref*")
    (goto-char (point-max))
    (insert "findDef:\n"))
  (let* ((path-pos (smlref-get-file-info))
         (res (smlref-execute-command (cons smlref-finddef-cmd path-pos)))
         (status (smlref-assoc 'status res))
         (pos (smlref-assoc 'pos res))
         (path (smlref-assoc 'path res))
         (filepath (concat (file-name-as-directory smlref-base-dir) path)))
    (cond
     ((equal status "OK")
      (let ((filebuf (find-file-noselect filepath)))
        (cond
         ((eq filebuf (current-buffer))
          (push-mark)
          (smlref-goto-char (+ pos 1)))
         (t (smlref-display-filebuf-pos filebuf pos)))))
      (t (message "status: NG")))))

(defun smlref-find-ref ()
  (interactive)
  (with-current-buffer (get-buffer-create "*sml#ref*")
    (goto-char (point-max))
    (insert "findRef:\n"))
  (let* ((path-pos (smlref-get-file-info))
         (res (smlref-execute-command (cons smlref-findref-cmd path-pos)))
         (status (smlref-assoc 'status res))
         (defSym (smlref-assoc 'defSym res))
         (files (smlref-assoc 'files res)))
    (let ((find-ref-buf (get-buffer-create "*sml#findRef*")))
      (set-buffer find-ref-buf)
      (read-only-mode -1)
      (erase-buffer)
      (insert "Reference points for " defSym ":\n\n")
      (mapc #'smlref-insert-file-pos files)
;    (display-buffer-at-bottom
;     findRefBuf
;     (list (cons 'window-height smlref-window-fraction)))
      (read-only-mode 1)
      (smlref-find-ref-mode)
      (switch-to-buffer-other-window find-ref-buf))))

;;;(setConfig)
;;;(global-set-key "\C-x\C-d" 'findDef) ; 現在のポイントの名前の定義を探し、別Windowsに表示
;;;(global-set-key "\C-x\C-r" 'findRef) ; 現在のポイントの名前の参照集合を探し、別Windowsに表示

(define-minor-mode smlref-mode
  "SML# ref mode"
  :global t
  :lighter " SMLRef"
  :group 'smlref
  :keymap '(("\C-x\C-d" . smlref-find-def)
            ("\C-x\C-r" . smlref-find-ref))
  (when smlref-mode (smlref-set-config)))

(defun smlref-find-ref-mode ()
  "SML# ref find ref mode"
  (interactive)
  (kill-all-local-variables)
  (setq mode-name "SMLFindRef")
  (setq major-mode 'smlref-find-ref-mode)
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-M" 'smlref-open-ref-point)
    (use-local-map map)))

(provide 'smlref-mode)
