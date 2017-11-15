
(setq user-full-name "Md. Alamin Mahamud")
(setq user-mail-address "alamin.ineedahelp@gmail.com")

;;  (if (fboundp 'gnutls-available-p)
;;      (fmakunbound 'gnutls-available-p))

(require 'cl)
(setq tls-checktrust t)

(let ((trustfile
       (replace-regexp-in-string
        "\\\\" "/"
        (replace-regexp-in-string
         "\n" ""
         (shell-command-to-string "python -m certifi")))))
  (setq tls-program
        (list
         (format "gnutls-cli%s --x509cafile %s -p %%p %%h"
                 (if (eq window-system 'w32) ".exe" "") trustfile)))
  (setq gnutls-verify-error t)
  (setq gnutls-trustfiles (list trustfile)))

;; Test the settings by using the following code snippet:
;;  (let ((bad-hosts
;;         (loop for bad
;;               in `("https://wrong.host.badssl.com/"
;;                    "https://self-signed.badssl.com/")
;;               if (condition-case e
;;                      (url-retrieve
;;                       bad (lambda (retrieved) t))
;;                    (error nil))
;;               collect bad)))
;;    (if bad-hosts
;;        (error (format "tls misconfigured; retrieved %s ok" bad-hosts))
;;      (url-retrieve "https://badssl.com"
;;                    (lambda (retrieved) t))))

(setq custom-file (concat init-dir "custom.el"))

(load custom-file :noerror)

(setq gc-cons-threshold 50000000)

(setq gnutls-min-prime-bits 4096)

(require 'package)

(defvar gnu '("gnu" . "https://elpa.gnu.org/packages/"))
(defvar melpa '("melpa" . "https://melpa.org/packages/"))
(defvar melpa-stable '("melpa-stable" . "https://stable.melpa.org/packages/"))

;; Add marmalade to package repos
(setq package-archives nil)
(add-to-list 'package-archives melpa-stable t)
(add-to-list 'package-archives melpa t)
(add-to-list 'package-archives gnu t)

(package-initialize)

(unless (and (file-exists-p "~/.emacs.d/elpa/archives/gnu")
             (file-exists-p "~/.emacs.d/elpa/archives/melpa")
             (file-exists-p "~/.emacs.d/elpa/archives/melpa-stable"))
  (package-refresh-contents))

(defun packages-install (&rest packages)
  (message "running packages-install")
  (mapc (lambda (package)
          (let ((name (car package))
                (repo (cdr package)))
            (unless (package-installed-p name)
              (let ((package-archives (list repo)))
                (package-initialize)
                (package-install name)))))
        packages)
  (package-initialize)
  (delete-other-windows))

;; Install extensions if they're missing
(defun init--install-packages ()
  (message "Lets install some packages")
  (packages-install
   ;; Since use-package this is the only entry here
   ;; ALWAYS try to use use-package!
   (cons 'use-package melpa))

)

(condition-case nil
    (init--install-packages)
  (error
   (package-refresh-contents)
   (init--install-packages)))

(require 'cl)

(use-package dash
:ensure t
:config (eval-after-load "dash" '(dash-enable-font-lock)))

(use-package s
:ensure t)

(use-package f
:ensure t)

(setq-default indent-tabs-mode nil)
(setq tab-width 2)

(setq-default tab-always-indent 'complete)

(fset 'yes-or-no-p 'y-or-n-p)

(setq scroll-conservatively 10000
      scroll-preserve-screen-position t)

(setq disabled-command-function nil)

(setq global-mark-ring-max 5000   ; increase mark ring to contains 5000 entries
      mark-ring-max 5000          ; increase kill to contains 5000 entries
      mode-require-final-newline t; add a newline to end of file
      )

(setq-default tab-width 2)
(setq-default indent-tabs-mode nil)

(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment "UTF-8")
(prefer-coding-system 'utf-8)

(setq
 kill-ring-max 5000 ; increase kill-ring capacity
 kill-whole-line t  ; if NIL, kill whole line and move the next line up
 )

(delete-selection-mode)
(global-set-key (kbd "RET") 'newline-and-indent)

(add-hook 'diff-mode-hook 
          (lambda ()
            (setq-local
             whitespace-style
             '(
               face
               tabs
               spaces
               space-mark
               trailing
               indentation::space
               indentation::tab
               newline
               newline-mark))
            (whitespace-mode 1)))

(defun prelude-move-beginning-of-line (arg)
     "Move point back to indentation of beginning of line.

   Move point to the first non-whitespace character on this line.
   If point is already there, move to the beginning of the line.
   Effectively toggle between the first non-whitespace character and
   the beginning of the line.

   If ARG is not nil or 1, move forward ARG - 1 lines first. If
   point reaches the beginning or end of the buffer, stop there."
     (interactive "^p")
     (setq arg (or arg 1))

     ;; Move lines first
     (when (/= arg 1)
       (let ((line-move visual nil))
         (forward-line (1- arg))))

     (let ((orig-point (point)))
       (back-to-indentation)
       (when (= origi-point (point))
         (move-beginning-of-line 1))))

  (global-set-key (kbd "C-a") 'prelude-move-beginning-of-line)
  (defadvice kill-ring-save (before slick-copy activate compile)
    "When called interactively with no active region, copy a single
  line instead."
    (interactive
     (if mark-active (list (region-beginning) (region-end))
       (message "Copied line")
       (list (line-beginning-position)
             (line-beginning-position 2)))))
(defadvice kill-region (before slick-cut activate compile)
  "When called interactively with no active region, kill a single
  line instead."
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (list (line-beginning-position)
           (line-beginning-position 2)))))

(defadvice kill-line (before check-position activate)
  (if (member major-mode
              '(emacs-lisp-mode scheme-mode lisp-mode
                                c-mode c++-mode objc-mode
                                latex-mode plain-tex-mode))
      (if (and (eolp) (not (bolp)))
          (progn (forward-char 1)
                 (just-one-space 0)
                 (backward-char 1)))))

;; prelude-core.el
(defun prelude-duplicate-current-line-or-region (arg)
  "Duplicates the current line or region ARG times.
If there's no region, the current line will be duplicated. However, if
there's a region, all lines that region covers will be duplicated."
  (interactive "p")
  (pcase-let* ((origin (point))
               (`(,beg . ,end) (prelude-get-positions-of-line-or-region))
               (region (buffer-substring-no-properties beg end)))
    (-dotimes arg
      (lambda (n)
        (goto-char end)
        (newline)
        (insert region)
        (setq end (point))))
    (goto-char (+ origin (* (length region) arg) arg))))

;; prelude-core.el
(defun indent-buffer ()
  "Indent the currently visited buffer."
  (interactive)
  (indent-region (point-min) (point-max)))
;; prelude-editing.el
(defcustom prelude-indent-sensitive-modes
  '(coffee-mode python-mode slim-mode haml-mode yaml-mode)
  "Modes for which auto-indenting is suppressed."
  :type 'list)

(defun indent-region-or-buffer ()
  "Indent a region if selected, otherwise the whole buffer."
  (interactive)
  (unless (member major-mode prelude-indent-sensitive-modes)
    (save-excursion
      (if (region-active-p)
          (progn
            (indent-region (region-beginning) (region-end))
            (message "Indented selected region."))
        (progn
          (indent-buffer)
          (message "Indented buffer.")))
      (whitespace-cleanup))))

(global-set-key (kbd "C-c i") 'indent-region-or-buffer)

;; add duplicate line function from Prelude
;; taken from prelude-core.el
(defun prelude-get-positions-of-line-or-region ()
  "Return positions (beg . end) of the current line
or region."
  (let (beg end)
    (if (and mark-active (> (point) (mark)))
        (exchange-point-and-mark))
    (setq beg (line-beginning-position))
    (if mark-active
        (exchange-point-and-mark))
    (setq end (line-end-position))
    (cons beg end)))

(defun kill-default-buffer ()
  "Kill the currently active buffer -- set to C-x k so that users are not asked which buffer they want to kill."
  (interactive)
  (let (kill-buffer-query-functions) (kill-buffer)))

(global-set-key (kbd "C-x k") 'kill-default-buffer)

;; smart openline
(defun prelude-smart-open-line (arg)
  "Insert an empty line after the current line.
Position the cursor at its beginning, according to the current mode.
With a prefix ARG open line above the current line."
  (interactive "P")
  (if arg
      (prelude-smart-open-line-above)
    (progn
      (move-end-of-line nil)
      (newline-and-indent))))

(defun prelude-smart-open-line-above ()
  "Insert an empty line above the current line.
Position the cursor at it's beginning, according to the current mode."
  (interactive)
  (move-beginning-of-line nil)
  (newline-and-indent)
  (forward-line -1)
  (indent-according-to-mode))

(global-set-key (kbd "C-o") 'prelude-smart-open-line)
(global-set-key (kbd "M-o") 'open-line)

(use-package duplicate-thing
:ensure t
:config
(require 'duplicate-thing)
(global-set-key (kbd "M-c") 'duplicate-thing))

(use-package volatile-highlights
:ensure t
:config
(require 'volatile-highlights)
(volatile-highlights-mode t))

(use-package smartparens-config
:ensure smartparens
:config
(progn 
(show-smartparens-global-mode t)))

(add-hook 'prog-mode-hook 'turn-on-smartparens-strict-mode)
(add-hook 'markdown-mode-hook 'turn-on-smartparens-strict-mode)
(bind-keys
 :map smartparens-mode-map
 ("C-M-a" . sp-beginning-of-sexp)
 ("C-M-e" . sp-end-of-sexp)

 ("C-<down>" . sp-down-sexp)
 ("C-<up>"   . sp-up-sexp)
 ("M-<down>" . sp-backward-down-sexp)
 ("M-<up>"   . sp-backward-up-sexp)

 ("C-M-f" . sp-forward-sexp)
 ("C-M-b" . sp-backward-sexp)

 ("C-M-n" . sp-next-sexp)
 ("C-M-p" . sp-previous-sexp)

 ("C-S-f" . sp-forward-symbol)
 ("C-S-b" . sp-backward-symbol)

 ("C-<right>" . sp-forward-slurp-sexp)
 ("M-<right>" . sp-forward-barf-sexp)
 ("C-<left>"  . sp-backward-slurp-sexp)
 ("M-<left>"  . sp-backward-barf-sexp)

 ("C-M-t" . sp-transpose-sexp)
 ("C-M-k" . sp-kill-sexp)
 ("C-k"   . sp-kill-hybrid-sexp)
 ("M-k"   . sp-backward-kill-sexp)
 ("C-M-w" . sp-copy-sexp)
 ("C-M-d" . delete-sexp)

 ("M-<backspace>" . backward-kill-word)
 ("C-<backspace>" . sp-backward-kill-word)
 ([remap sp-backward-kill-word] . backward-kill-word)

 ("M-[" . sp-backward-unwrap-sexp)
 ("M-]" . sp-unwrap-sexp)

 ("C-x C-t" . sp-transpose-hybrid-sexp)

 ("C-c ("  . wrap-with-parens)
 ("C-c ["  . wrap-with-brackets)
 ("C-c {"  . wrap-with-braces)
 ("C-c M-'"  . wrap-with-single-quotes)
 ("C-c \"" . wrap-with-double-quotes)
 ("C-c _"  . wrap-with-underscores)
 ("C-c `"  . wrap-with-back-quotes))

(use-package clean-aindent-mode
:ensure t
:config
(require 'clean-aindent-mode))

(add-hook 'prog-mode-hook 'clean-aindent-mode)

(use-package undo-tree
:ensure t
:config
(require 'undo-tree)
(global-undo-tree-mode))

(use-package yasnippet
:ensure t
:config
(require 'yasnippet)
(yas-global-mode 1))

(global-auto-revert-mode)

(use-package workgroups2
:ensure t
:config
(require 'workgroups2)

;; Change prefix key (before activating WG)
(setq wg-prefix-key (kbd "C-c z"))
;; Change workgroups session file
(setq wg-session-file "~/.emacs.d/.emacs_workgroups")
;; What to do on Emacs exit / workgroups-mode exit?
(setq wg-emacs-exit-save-behavior           'save)
(setq wg-workgroups-mode-exit-save-behavior 'save)

;; Mode Line Changes
;; Display workgroups in Mode Line?
(setq wg-mode-line-display-on t)
(setq wg-flag-modified t)
(setq wg-mode-line-decor-left-brace "["
      wg-mode-line-decor-right-brace "]"
      wg-mode-line-decor-divider ":")
(workgroups-mode 1))

(global-set-key (kbd "M-/") 'hippie-expand) ;; replace dabbrev-expand
(setq
hippie-expand-try-functions-list
'(try-expand-dabbrev ;; Try to expand word "dynamically", searching the current buffer.
   try-expand-dabbrev-all-buffers ;; Try to expand word "dynamically", searching all other buffers.
   try-expand-dabbrev-from-kill ;; Try to expand word "dynamically", searching the kill ring.
   try-complete-file-name-partially ;; Try to complete text as a file name, as many characters as unique.
   try-complete-file-name ;; Try to complete text as a file name.
   try-expand-all-abbrevs ;; Try to expand word before point according to all abbrev tables.
   try-expand-list ;; Try to complete the current line to an entire line in the buffer.
   try-expand-line ;; Try to complete the current line to an entire line in the buffer.
   try-complete-lisp-symbol-partially ;; Try to complete as an Emacs Lisp symbol, as many characters as unique.
   try-complete-lisp-symbol) ;; Try to complete word as an Emacs Lisp symbol. 
)

(global-hl-line-mode)

(setq ibuffer-use-other-window t) ;; always display ibuffer in another window

(add-hook 'prog-mode-hook 'linum-mode) ;; enable linum only in programmin modes

;; whenever you create useless whitespace, the whitespace is highlighted
(add-hook 'prog-mode-hook (lambda () (interactive) (setq show-trailing-whitespace 1)))

;; activate whitespace-mode to view all whitespace characters
(global-set-key (kbd "C-c w") 'whitespace-mode)

(windmove-default-keybindings)

(use-package company
:ensure t
:config
(add-hook 'after-init-hook 'global-company-mode))

(use-package expand-region
:ensure t
:config
(require 'expand-region)
(global-set-key (kbd "M-m") 'er/expand-region))

(use-package ibuffer-vc
  :ensure t
  :config
  (add-hook 'ibuffer-hook
            (lambda ()
              (ibuffer-vc-set-filter-groups-by-vc-root)
              (unless (eq ibuffer-sorting-mode 'alphabetic)
                (ibuffer-do-sort-by-alphabetic))))
(setq ibuffer-formats
      '((mark modified read-only vc-status-mini " "
              (name 18 18 :left :elide)
              " "
              (size 9 -1 :right)
              " "
              (mode 16 16 :left :elide)
              " "
              (vc-status 16 16 :left)
              " "
              filename-and-process))))

(use-package projectile
:ensure t
:config
(projectile-global-mode))

(use-package helm
  :ensure t
  :config
  (require 'helm)
  (require 'helm-config)

  ;; The default "C-x c" is quite close to "C-x C-c", which quits Emacs.
  ;; Changed to "C-c h". Note: We must set "C-c h" globally, because we
  ;; cannot change `helm-command-prefix-key' once `helm-config' is loaded.
  (global-set-key (kbd "C-c h") 'helm-command-prefix)
  (global-unset-key (kbd "C-x c"))

  (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action
  (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB work in terminal
  (define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

  (when (executable-find "curl")
    (setq helm-google-suggest-use-curl-p t))

  (setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
      helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
      helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
      helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
      helm-ff-file-name-history-use-recentf t
      helm-echo-input-in-header-line t)

  (defun spacemacs//helm-hide-minibuffer-maybe ()
  "Hide minibuffer in Helm session if we use the header line as input field."
  (when (with-helm-buffer helm-echo-input-in-header-line)
    (let ((ov (make-overlay (point-min) (point-max) nil nil t)))
      (overlay-put ov 'window (selected-window))
      (overlay-put ov 'face
                   (let ((bg-color (face-background 'default nil)))
                     `(:background ,bg-color :foreground ,bg-color)))
      (setq-local cursor-type nil))))


  (add-hook 'helm-minibuffer-set-up-hook
            'spacemacs//helm-hide-minibuffer-maybe)

  (setq helm-autoresize-max-height 0)
  (setq helm-autoresize-min-height 20)
  (helm-autoresize-mode 1)
  (helm-mode 1))

(setq projectile-completion-system 'helm)
(use-package helm-projectile
:ensure t
:config
(helm-projectile-on))

(setq projectile-switch-project-action 'helm-projectile)

(setq projectile-enable-caching t)

(helm-autoresize-mode t)

(global-set-key (kbd "M-x") 'helm-M-x)
(setq helm-M-x-fuzzy-match t) ;; optional fuzzy matching for helm-M-x

(global-set-key (kbd "C-x b") 'helm-mini)

(setq helm-buffers-fuzzy-matching t
      helm-recentf-fuzzy-match    t)

(when (executable-find "ack-grep")
(setq helm-grep-default-command "ack-grep -Hn --no-group --no-color %e %p %f"
      helm-grep-default-recurse-command "ack-grep -H --no-group --no-color %e %p %f"))

(setq helm-semantic-fuzzy-match t
      helm-imenu-fuzzy-match    t)

(add-to-list 'helm-sources-using-default-as-input 'helm-source-man-pages)

(setq helm-locate-fuzzy-match t)

(global-set-key (kbd "C-c h o") 'helm-occur)

(use-package helm-descbinds
:ensure t
:config
(require 'helm-descbinds)
(helm-descbinds-mode))

(setq large-file-warning-threshold 100000000) ;; size in bytes

(defvar backup-directory "~/.backups")
(if (not (file-exists-p backup-directory))
    (make-directory backup-directory t))
(setq
 make-backup-files t        ; backup a file the first time it is saved
 backup-directory-alist `((".*" . ,backup-directory)) ; save backup files in ~/.backups
 backup-by-copying t     ; copy the current file into backup directory
 version-control t   ; version numbers for backup files
 delete-old-versions t   ; delete unnecessary versions
 kept-old-versions 6     ; oldest versions to keep when a new numbered backup is made (default: 2)
 kept-new-versions 9 ; newest versions to keep when a new numbered backup is made (default: 2)
 auto-save-default t ; auto-save every buffer that visits a file
 auto-save-timeout 20 ; number of seconds idle time before auto-save (default: 30)
 auto-save-interval 200 ; number of keystrokes between auto-saves (default: 300)
 )

(setq
 dired-dwim-target t            ; if another Dired buffer is visible in another window, use that directory as target for Rename/Copy
 dired-recursive-copies 'always         ; "always" means no asking
 dired-recursive-deletes 'top           ; "top" means ask once for top level directory
 dired-listing-switches "-lha"          ; human-readable listing
 )

(add-hook 'dired-mode-hook 'auto-revert-mode)

;; if it is not Windows, use the following listing switches
(when (not (eq system-type 'windows-nt))
  (setq dired-listing-switches "-lha --group-directories-first"))
(require 'dired-x)

;; - Switch to Wdired by C-x C-q
;; - Edit the Dired buffer, i.e. change filenames
;; - Commit by C-c C-c, abort by C-c C-k
(require 'wdired)
(setq
 wdired-allow-to-change-permissions t   ; allow to edit permission bits
 wdired-allow-to-redirect-links t       ; allow to edit symlinks
 )

(use-package recentf-mode
:ensure t
:config
(recentf-mode)
(setq
recentf-max-menu-items 30
recentf-max-saved-items 5000
))

(use-package dired+
:ensure t
:config
(require 'dired+))

(use-package recentf-ext
:ensure t
:config
(require 'recentf-ext))

(use-package ztree
:ensure t
:config 
(require 'ztree-diff)
(require 'ztree-dir))

;; saveplace remembers your location in a file when saving files
(require 'saveplace)
(setq-default save-place t)

(if (executable-find "aspell")
    (progn
      (setq ispell-program-name "aspell")
      (setq ispell-extra-args '("--sug-mode=ultra")))
  (setq ispell-program-name "ispell"))

(add-hook 'text-mode-hook 'flyspell-mode)
(add-hook 'org-mode-hook 'flyspell-mode)
(add-hook 'prog-mode-hook 'flyspell-prog-mode)

(setq gud-chdir-before-run nil)

(defun my-term-setup ()
  (interactive)
  (define-key term-raw-map (kbd "C-y") 'term-send-raw)
  (define-key term-raw-map (kbd "C-p") 'term-send-raw)
  (define-key term-raw-map (kbd "C-n") 'term-send-raw)
  (define-key term-raw-map (kbd "C-s") 'term-send-raw)
  (define-key term-raw-map (kbd "C-r") 'term-send-raw)
  (define-key term-raw-map (kbd "M-w") 'kill-ring-save)
  (define-key term-raw-map (kbd "M-y") 'helm-show-kill-ring)
  (define-key term-raw-map (kbd "M-d") (lambda () (interactive) (term-send-raw-string "\ed")))
  (define-key term-raw-map (kbd "<C-backspace>") (lambda () (interactive) (term-send-raw-string "\e\C-?")))
  (define-key term-raw-map (kbd "M-p") (lambda () (interactive) (term-send-raw-string "\ep")))
  (define-key term-raw-map (kbd "M-n") (lambda () (interactive) (term-send-raw-string "\en")))
  (define-key term-raw-map (kbd "M-,") 'term-send-input)
  (define-key term-raw-map (kbd "C-c y") 'term-paste)
  (define-key term-raw-map (kbd "C-S-y") 'term-paste)
  (define-key term-raw-map (kbd "C-h") nil) ; unbind C-h
  (define-key term-raw-map (kbd "M-x") nil) ; unbind M-x
  (define-key term-raw-map (kbd "C-c C-b") 'helm-mini)
  (define-key term-raw-map (kbd "C-1") 'zygospore-toggle-delete-other-windows)
  (define-key term-raw-map (kbd "C-2") 'split-window-below)
  (define-key term-raw-map (kbd "C-3") 'split-window-right)
  (define-key term-mode-map (kbd "C-0") 'delete-window))
(add-hook 'term-mode-hook 'my-term-setup t)
(setq term-buffer-maximum-size 0)
(require 'term)

(defun visit-ansi-term ()
  "If the current buffer is:
     1) a running ansi-term named *ansi-term*, rename it.
     2) a stopped ansi-term, kill it and create a new one.
     3) a non ansi-term, go to an already running ansi-term
        or start a new one while killing a defunt one"
  (interactive)
  (let ((is-term (string= "term-mode" major-mode))
        (is-running (term-check-proc (buffer-name)))
        (term-cmd "/bin/zsh")
        (anon-term (get-buffer "*ansi-term*")))
    (if is-term
        (if is-running
            (if (string= "*ansi-term*" (buffer-name))
                ;; (call-interactively 'rename-buffer)
                (ansi-term term-cmd)
              (if anon-term
                  (switch-to-buffer "*ansi-term*")
                (ansi-term term-cmd)))
          (kill-buffer (buffer-name))
          (ansi-term term-cmd))
      (if anon-term
          (if (term-check-proc "*ansi-term*")
              (switch-to-buffer "*ansi-term*")
            (kill-buffer "*ansi-term*")
            (ansi-term term-cmd))
        (ansi-term term-cmd)))))

(global-set-key (kbd "<f2>") 'visit-ansi-term)

(use-package shell-pop
:ensure t
:config
(require 'shell-pop)
(global-set-key (kbd "C-c t") 'shell-pop))

;; go-to-address-mode
(add-hook 'prog-mode-hook 'goto-address-mode)
(add-hook 'text-mode-hook 'goto-address-mode)

(setq c-default-style "linux" ; set style to "linux"
      c-basic-offset 4)

(setq gdb-many-windows t
      gdb-show-main t)

;; Compilation from Emacs
(defun prelude-colorize-compilation-buffer ()
  "Colorize a compilation mode buffer."
  (interactive)
  ;; we don't want to mess with child modes such as grep-mode, ack, ag, etc
  (when (eq major-mode 'compilation-mode)
    (let ((inhibit-read-only t))
      (ansi-color-apply-on-region (point-min) (point-max)))))

;; setup compilation-mode used by `compile' command
(require 'compile)
(setq compilation-ask-about-save nil ; just save before compiling
      compilation-always-kill t      ; just kill old compile process before starting the new one
      compilation-scroll-output 'first-error) ; automatically scroll to first
(global-set-key (kbd "<f5>") 'compile)

;; takenn from prelude-c.el:48: https://github.com/bbatsov/prelude/blob/master/modules/prelude-c.el
(defun prelude-makefile-mode-defaults ()
  (whitespace-toggle-options '(tabs))
  (setq indent-tabs-mode t))

(setq prelude-makefile-mode-hook 'prelude-makefile-mode-defaults)

(add-hook 'makefile-mode-hook (lambda ()
                                (run-hooks 'prelude-makefile-mode-hook)))

(setq ediff-diff-options "-w"
      ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

(use-package magit
  :ensure t
  :config
  (require 'magit)
  (set-default 'magit-stage-all-confirm nil)

 ;; full screen magit-status
(defadvice magit-status (around magit-fullscreen activate)
  (window-configuration-to-register :magit-fullscreen)
  ad-do-it
  (delete-other-windows))

(global-unset-key (kbd "C-x g"))
(global-set-key (kbd "C-x g h") 'magit-log)
(global-set-key (kbd "C-x g f") 'magit-file-log)
(global-set-key (kbd "C-x g b") 'magit-blame-mode)
(global-set-key (kbd "C-x g m") 'magit-branch-manager)
(global-set-key (kbd "C-x g c") 'magit-branch)
(global-set-key (kbd "C-x g s") 'magit-status)
(global-set-key (kbd "C-x g r") 'magit-reflog)
(global-set-key (kbd "C-x g t") 'magit-tag))

(use-package flycheck
:ensure t
:config
(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode))

(use-package flycheck-tip
:ensure t)
(require 'flycheck-tip)
;(flycheck-tip-use-timer 'verbose)

(require 'eshell)
(require 'em-alias)
(require 'cl)

;; Advise find-file-other-window to accept more than one file
(defadvice find-file-other-window (around find-files activate)
  "Also find all files within a list of files. This even works recursively."
  (if (listp filename)
      (loop for f in filename do (find-file-other-window f wildcards))
    ad-do-it))

;; In Eshell, you can run the commands in M-x
;; Here are the aliases to the commands.
;; $* means accepts all arguments.
(eshell/alias "o" "")
(eshell/alias "o" "find-file-other-window $*")
(eshell/alias "vi" "find-file-other-window $*")
(eshell/alias "vim" "find-file-other-window $*")
(eshell/alias "emacs" "find-file-other-windpow $*")
(eshell/alias "em" "find-file-other-window $*")

(add-hook
 'eshell-mode-hook
 (lambda ()
   (setq pcomplete-cycle-completions nil)))

;; change listing switches based on OS
(when (not (eq system-type 'windows-nt))
  (eshell/alias "ls" "ls --color -h --group-directories-first $*"))

(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
(add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)

(setq gc-cons-threshold 100000000)

(setq inhibit-startup-screen t)

;(icomplete-mode)

;; savehist saves minibuffer history by defaults
(setq savehist-additional-variables '(search ring regexp-search-ring) ; also save your regexp search queries
      savehist-autosave-interval 60     ; save every minute
      )

(use-package golden-ratio
:ensure t
:config
(require 'golden-ratio)

(add-to-list 'golden-ratio-exclude-modes "ediff-mode")
(add-to-list 'golden-ratio-exclude-modes "helm-mode")
(add-to-list 'golden-ratio-exclude-modes "dired-mode")
(add-to-list 'golden-ratio-inhibit-functions 'pl/helm-alive-p)

(defun pl/helm-alive-p ()
  (if (boundp 'helm-alive-p)
      (symbol-value 'helm-alive-p)))

;; do not enable golden-raio in thses modes
(setq golden-ratio-exclude-modes '("ediff-mode"
                                   "gud-mode"
                                   "gdb-locals-mode"
                                   "gdb-registers-mode"
                                   "gdb-breakpoints-mode"
                                   "gdb-threads-mode"
                                   "gdb-frames-mode"
                                   "gdb-inferior-io-mode"
                                   "gud-mode"
                                   "gdb-inferior-io-mode"
                                   "gdb-disassembly-mode"
                                   "gdb-memory-mode"
                                   "magit-log-mode"
                                   "magit-reflog-mode"
                                   "magit-status-mode"
                                   "IELM"
                                   "eshell-mode" "dired-mode"))

(golden-ratio-mode))

(winner-mode 1)

(column-number-mode 1)

(setq initial-scratch-message "Alamin <3 Emacs")

(if (or
     (eq system-type 'darwin)
     (eq system-type 'berkeley-unix))
    (setq system-name (car (split-string system-name "\\."))))

(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
(push "/usr/local/bin" exec-path)

;; /usr/libexec/java_home
;;(setenv "JAVA_HOME" "/Library/Java/JavaVirtualMachines/jdk1.8.0_05.jdk/Contents/Home")

(use-package which-key
  :ensure t
  :diminish which-key-mode
  :config
  (which-key-mode))

(use-package bm
  :ensure t
  :bind (("C-c =" . bm-toggle)
         ("C-c [" . bm-previous)
         ("C-c ]" . bm-next)))

(use-package counsel
  :ensure t
  :bind
  (("M-x" . counsel-M-x)
   ("M-y" . counsel-yank-pop)
   :map ivy-minibuffer-map
   ("M-y" . ivy-next-line)))

 (use-package swiper
   :pin melpa-stable
   :diminish ivy-mode
   :ensure t
   :bind*
   (("C-s" . swiper)
    ("C-c C-r" . ivy-resume)
    ("C-x C-f" . counsel-find-file)
    ("C-c h f" . counsel-describe-function)
    ("C-c h v" . counsel-describe-variable)
    ("C-c i u" . counsel-unicode-char)
    ("M-i" . counsel-imenu)
    ("C-c g" . counsel-git)
    ("C-c j" . counsel-git-grep)
    ("C-c k" . counsel-ag)
    ("C-c l" . scounsel-locate))
   :config
   (progn
     (ivy-mode 1)
     (setq ivy-use-virtual-buffers t)
     (define-key read-expression-map (kbd "C-r") #'counsel-expression-history)
     (ivy-set-actions
      'counsel-find-file
      '(("d" (lambda (x) (delete-file (expand-file-name x)))
         "delete"
         )))
     (ivy-set-actions
      'ivy-switch-buffer
      '(("k"
         (lambda (x)
           (kill-buffer x)
           (ivy--reset-state ivy-last))
         "kill")
        ("j"
         ivy--switch-buffer-other-window-action
         "other window")))))

(use-package counsel-projectile
  :ensure t
  :config
  (counsel-projectile-on))

(use-package ivy-hydra :ensure t)

(global-set-key (kbd "C-x k") 'kill-this-buffer)

(setq mouse-wheel-scroll-amount '(1 ((shift) . 1) ((control) . nil)))
(setq mouse-wheel-progressive-speed nil)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq mac-option-modifier 'none)
(setq mac-command-modifier 'meta)
(setq ns-function-modifier 'hyper)

;; Backup settings
(defvar --backup-directory (concat init-dir "backups"))

(if (not (file-exists-p --backup-directory))
    (make-directory --backup-directory t))

(setq backup-directory-alist `(("." . ,--backup-directory)))
(setq make-backup-files t               ; backup of a file the first time it is saved.
      backup-by-copying t               ; don't clobber symlinks
      version-control t                 ; version numbers for backup files
      delete-old-versions t             ; delete excess backup files silently
      delete-by-moving-to-trash t
      kept-old-versions 6               ; oldest versions to keep when a new numbered backup is made (default: 2)
      kept-new-versions 9               ; newest versions to keep when a new numbered backup is made (default: 2)
      auto-save-default t               ; auto-save every buffer that visits a file
      auto-save-timeout 20              ; number of seconds idle time before auto-save (default: 30)
      auto-save-interval 200            ; number of keystrokes between auto-saves (default: 300)
      )
  (setq delete-by-moving-to-trash t
        trash-directory "~/.Trash/emacs")

  (setq backup-directory-alist `(("." . ,(expand-file-name
                                          (concat init-dir "backups")))))

(setq ns-pop-up-frames nil)

(defun spell-buffer-dutch ()
  (interactive)
  (ispell-change-dictionary "nl_NL")
  (flyspell-buffer))

(defun spell-buffer-english ()
  (interactive)
  (ispell-change-dictionary "en_US")
  (flyspell-buffer))

(use-package ispell
  :config
  (when (executable-find "hunspell")
    (setq-default ispell-program-name "hunspell")
    (setq ispell-really-hunspell t))

  ;; (setq ispell-program-name "aspell"
  ;;       ispell-extra-args '("--sug-mode=ultra"))
  :bind (("C-c N" . spell-buffer-dutch)
         ("C-c n" . spell-buffer-english)))

;;; what-face to determine the face at the current point
(defun what-face (pos)
  (interactive "d")
  (let ((face (or (get-char-property (point) 'read-face-name)
                  (get-char-property (point) 'face))))
    (if face (message "Face: %s" face) (message "No face at %d" pos))))

(use-package ace-window
  :ensure t
  :config
  (setq aw-keys '(?a ?s ?d ?f ?j ?k ?l ?o))
  (global-set-key (kbd "C-x o") 'ace-window)
:diminish ace-window-mode)

(use-package ace-jump-mode
  :ensure t
  :config
  (define-key global-map (kbd "C-c SPC") 'ace-jump-mode))

;; Custom binding for magit-status
  (use-package magit
    :config
    (global-set-key (kbd "C-c m") 'magit-status))

  (setq inhibit-startup-message t)
;;  (global-linum-mode)

  (defun iwb ()
    "indent whole buffer"
    (interactive)
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max)))

  (global-set-key (kbd "C-c n") 'iwb)

  (electric-pair-mode t)

(use-package arjen-grey-theme
   :ensure t
   :config
   (load-theme 'arjen-grey t))

 ;; (use-package base16-theme
 ;;   :ensure t
 ;;   :config
 ;;   (load-theme 'base16-materia))

(if (or (eq system-type 'darwin)(eq system-type 'gnu/linux) )
    (set-face-attribute 'default nil :font "Hack-16")
  (set-face-attribute 'default nil :font "DejaVu Sans Mono" :height 110))

(use-package command-log-mode
  :ensure t)

(defun live-coding ()
  (interactive)
  (set-face-attribute 'default nil :font "Hack-18")
  (add-hook 'prog-mode-hook 'command-log-mode)
  ;;(add-hook 'prog-mode-hook (lambda () (focus-mode 1)))
  )

(defun normal-coding ()
  (interactive)
  (set-face-attribute 'default nil :font "Hack-14")
  (add-hook 'prog-mode-hook 'command-log-mode)
  ;;(add-hook 'prog-mode-hook (lambda () (focus-mode 1)))
  )

(eval-after-load "org-indent" '(diminish 'org-indent-mode))

;;   (use-package all-the-icons
;;     :ensure t)

;; http://stackoverflow.com/questions/11679700/emacs-disable-beep-when-trying-to-move-beyond-the-end-of-the-document
(defun my-bell-function ())

(setq ring-bell-function 'my-bell-function)
(setq visible-bell nil)

;; ;;; Setup perspectives, or workspaces, to switch between
;; (use-package perspective
;;   :ensure t
;;   :config
;;   ;; Enable perspective mode
;;   (persp-mode t)
;;   (defmacro custom-persp (name &rest body)
;;     `(let ((initialize (not (gethash ,name perspectives-hash)))
;;            (current-perspective persp-curr))
;;        (persp-switch ,name)
;;        (when initialize ,@body)
;;        (setq persp-last current-perspective)))

;;   ;; Jump to last perspective
;;   (defun custom-persp-last ()
;;     (interactive)
;;     (persp-switch (persp-name persp-last)))

;;   (define-key persp-mode-map (kbd "C-x p -") 'custom-persp-last)

;;   (defun custom-persp/emacs ()
;;     (interactive)
;;     (custom-persp "emacs"
;;                   (find-file (concat init-dir "init.el"))))

;;   (define-key persp-mode-map (kbd "C-x p e") 'custom-persp/emacs)

;;   (defun custom-persp/qttt ()
;;     (interactive)
;;     (custom-persp "qttt"
;;                   (find-file "/Users/arjen/BuildFunThings/Projects/Clojure/Game/qttt/project.clj")))

;;   (define-key persp-mode-map (kbd "C-x p q") 'custom-persp/qttt)

;;   (defun custom-persp/trivia ()
;;     (interactive)
;;     (custom-persp "trivia"
;;                   (find-file "/Users/arjen/BuildFunThings/Projects/Clojure/trivia/project.clj")))

;;   (define-key persp-mode-map (kbd "C-x p t") 'custom-persp/trivia)

;;   (defun custom-persp/mail ()
;;     (interactive)
;;     (custom-persp "mail"
;;                   (mu4e)))

;;   (define-key persp-mode-map (kbd "C-x p m") 'custom-persp/mail)
;;   )

(use-package request
:ensure t)

;;(add-to-list 'load-path (expand-file-name (concat init-dir "ox-leanpub")))
;;(load-library "ox-leanpub")
(add-to-list 'load-path (expand-file-name (concat init-dir "ox-ghost")))
(load-library "ox-ghost")
;;; http://www.lakshminp.com/publishing-book-using-org-mode

;;(defun leanpub-export ()
;;  "Export buffer to a Leanpub book."
;;  (interactive)
;;  (if (file-exists-p "./Book.txt")
;;      (delete-file "./Book.txt"))
;;  (if (file-exists-p "./Sample.txt")
;;      (delete-file "./Sample.txt"))
;;  (org-map-entries
;;   (lambda ()
;;     (let* ((level (nth 1 (org-heading-components)))
;;            (tags (org-get-tags))
;;            (title (or (nth 4 (org-heading-components)) ""))
;;            (book-slug (org-entry-get (point) "TITLE"))
;;            (filename
;;             (or (org-entry-get (point) "EXPORT_FILE_NAME") (concat (replace-regexp-in-string " " "-" (downcase title)) ".md"))))
;;       (when (= level 1) ;; export only first level entries
;;         ;; add to Sample book if "sample" tag is found.
;;         (when (or (member "sample" tags)
;;                   ;;(string-prefix-p "frontmatter" filename) (string-prefix-p "mainmatter" filename)
;;                   )
;;           (append-to-file (concat filename "\n\n") nil "./Sample.txt"))
;;         (append-to-file (concat filename "\n\n") nil "./Book.txt")
;;         ;; set filename only if the property is missing
;;         (or (org-entry-get (point) "EXPORT_FILE_NAME")  (org-entry-put (point) "EXPORT_FILE_NAME" filename))
;;         (org-leanpub-export-to-markdown nil 1 nil)))) "-noexport")
;;  (org-save-all-org-buffers)
;;  nil
;;  nil)
;;
;;(require 'request)
;;
;;(defun leanpub-preview ()
;;  "Generate a preview of your book @ Leanpub."
;;  (interactive)
;;  (request
;;   "https://leanpub.com/clojure-on-the-server/preview.json" ;; or better yet, get the book slug from the buffer
;;   :type "POST"                                             ;; and construct the URL
;;   :data '(("api_key" . ""))
;;   :parser 'json-read
;;   :success (function*
;;             (lambda (&key data &allow-other-keys)
;;               (message "Preview generation queued at leanpub.com.")))))

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda ()
                   (flyspell-mode 1)
                   (visual-line-mode  1))))

(use-package markdown-mode
:ensure t)

(use-package htmlize
:ensure t)

(defun my/with-theme (theme fn &rest args)
  (let ((current-themes custom-enabled-themes))
    (mapcar #'disable-theme custom-enabled-themes)
    (load-theme theme t)
    (let ((result (apply fn args)))
      (mapcar #'disable-theme custom-enabled-themes)
      (mapcar (lambda (theme) (load-theme theme t)) current-themes)
      result)))
;;(advice-add #'org-export-to-file :around (apply-partially #'my/with-theme 'arjen-grey))
;;(advice-add #'org-export-to-buffer :around (apply-partially #'my/with-theme 'arjen-grey))

(use-package mode-icons
  :ensure t
  :config
  (mode-icons-mode t)
)

;;  (use-package spaceline
;;    :ensure t
;;    :init
;;    (setq powerline-default-separator 'utf-8)
;;
;;    :config
;;    (require 'spaceline-config)
;;    (spaceline-spacemacs-theme)
;;    )

(use-package f
    :ensure t)

  (use-package projectile
    :ensure t
    :config
    (add-hook 'prog-mode-hook 'projectile-mode))

(use-package powerline
    :ensure t
    :config
    (defvar mode-line-height 30 "A little bit taller, a little bit baller.")

    (defvar mode-line-bar          (eval-when-compile (pl/percent-xpm mode-line-height 100 0 100 0 3 "#909fab" nil)))
    (defvar mode-line-eldoc-bar    (eval-when-compile (pl/percent-xpm mode-line-height 100 0 100 0 3 "#B3EF00" nil)))
    (defvar mode-line-inactive-bar (eval-when-compile (pl/percent-xpm mode-line-height 100 0 100 0 3 "#9091AB" nil)))

    ;; Custom faces
    (defface mode-line-is-modified nil
      "Face for mode-line modified symbol")

    (defface mode-line-2 nil
      "The alternate color for mode-line text.")

    (defface mode-line-highlight nil
      "Face for bright segments of the mode-line.")

    (defface mode-line-count-face nil
      "Face for anzu/evil-substitute/evil-search number-of-matches display.")

    ;; Git/VCS segment faces
    (defface mode-line-vcs-info '((t (:inherit warning)))
      "")
    (defface mode-line-vcs-warning '((t (:inherit warning)))
      "")

    ;; Flycheck segment faces
    (defface doom-flycheck-error '((t (:inherit error)))
      "Face for flycheck error feedback in the modeline.")
    (defface doom-flycheck-warning '((t (:inherit warning)))
      "Face for flycheck warning feedback in the modeline.")


    (defun doom-ml-flycheck-count (state)
      "Return flycheck information for the given error type STATE."
      (when (flycheck-has-current-errors-p state)
        (if (eq 'running flycheck-last-status-change)
            "?"
          (cdr-safe (assq state (flycheck-count-errors flycheck-current-errors))))))

    (defun doom-fix-unicode (font &rest chars)
      "Display certain unicode characters in a specific font.
  e.g. (doom-fix-unicode \"DejaVu Sans\" ?⚠ ?★ ?λ)"
      (declare (indent 1))
      (mapc (lambda (x) (set-fontset-font
                    t (cons x x)
                    (cond ((fontp font)
                           font)
                          ((listp font)
                           (font-spec :family (car font) :size (nth 1 font)))
                          ((stringp font)
                           (font-spec :family font))
                          (t (error "FONT is an invalid type: %s" font)))))
            chars))

    ;; Make certain unicode glyphs bigger for the mode-line.
    ;; FIXME Replace with all-the-icons?
    (doom-fix-unicode '("DejaVu Sans Mono" 15) ?✱) ;; modified symbol
    (let ((font "DejaVu Sans Mono for Powerline")) ;;
      (doom-fix-unicode (list font 12) ?)  ;; git symbol
      (doom-fix-unicode (list font 16) ?∄)  ;; non-existent-file symbol
      (doom-fix-unicode (list font 15) ?)) ;; read-only symbol

    ;; So the mode-line can keep track of "the current window"
    (defvar mode-line-selected-window nil)
    (defun doom|set-selected-window (&rest _)
      (let ((window (frame-selected-window)))
        (when (and (windowp window)
                   (not (minibuffer-window-active-p window)))
          (setq mode-line-selected-window window))))
    (add-hook 'window-configuration-change-hook #'doom|set-selected-window)
    (add-hook 'focus-in-hook #'doom|set-selected-window)
    (advice-add 'select-window :after 'doom|set-selected-window)
    (advice-add 'select-frame  :after 'doom|set-selected-window)

    (defun doom/project-root (&optional strict-p)
      "Get the path to the root of your project."
      (let (projectile-require-project-root strict-p)
        (projectile-project-root)))

    (defun *buffer-path ()
      "Displays the buffer's full path relative to the project root (includes the
  project root). Excludes the file basename. See `*buffer-name' for that."
      (when buffer-file-name
        (propertize
         (f-dirname
          (let ((buffer-path (file-relative-name buffer-file-name (doom/project-root)))
                (max-length (truncate (/ (window-body-width) 1.75))))
            (concat (projectile-project-name) "/"
                    (if (> (length buffer-path) max-length)
                        (let ((path (reverse (split-string buffer-path "/" t)))
                              (output ""))
                          (when (and path (equal "" (car path)))
                            (setq path (cdr path)))
                          (while (and path (<= (length output) (- max-length 4)))
                            (setq output (concat (car path) "/" output))
                            (setq path (cdr path)))
                          (when path
                            (setq output (concat "../" output)))
                          (when (string-suffix-p "/" output)
                            (setq output (substring output 0 -1)))
                          output)
                      buffer-path))))
         'face (if active 'mode-line-2))))

    (defun *buffer-name ()
      "The buffer's base name or id."
      ;; FIXME Don't show uniquify tags
      (s-trim-left (format-mode-line "%b")))

    (defun *buffer-pwd ()
      "Displays `default-directory', for special buffers like the scratch buffer."
      (propertize
       (concat "[" (abbreviate-file-name default-directory) "]")
       'face 'mode-line-2))

    (defun *buffer-state ()
      "Displays symbols representing the buffer's state (non-existent/modified/read-only)"
      (when buffer-file-name
        (propertize
         (concat (if (not (file-exists-p buffer-file-name))
                     "∄"
                   (if (buffer-modified-p) "✱"))
                 (if buffer-read-only ""))
         'face 'mode-line-is-modified)))

    (defun *buffer-encoding-abbrev ()
      "The line ending convention used in the buffer."
      (if (memq buffer-file-coding-system '(utf-8 utf-8-unix))
          ""
        (symbol-name buffer-file-coding-system)))

    (defun *major-mode ()
      "The major mode, including process, environment and text-scale info."
      (concat (format-mode-line mode-name)
              (if (stringp mode-line-process) mode-line-process)
              (and (featurep 'face-remap)
                   (/= text-scale-mode-amount 0)
                   (format " (%+d)" text-scale-mode-amount))))

    (defun *vc ()
      "Displays the current branch, colored based on its state."
      (when vc-mode
        (let ((backend (concat " " (substring vc-mode (+ 2 (length (symbol-name (vc-backend buffer-file-name)))))))
              (face (let ((state (vc-state buffer-file-name)))
                      (cond ((memq state '(edited added))
                             'mode-line-vcs-info)
                            ((memq state '(removed needs-merge needs-update conflict removed unregistered))
                             'mode-line-vcs-warning)))))
          (if active
              (propertize backend 'face face)
            backend))))

    (defvar-local doom--flycheck-err-cache nil "")
    (defvar-local doom--flycheck-cache nil "")
    (defun *flycheck ()
      "Persistent and cached flycheck indicators in the mode-line."
      (when (and (featurep 'flycheck)
                 flycheck-mode
                 (or flycheck-current-errors
                     (eq 'running flycheck-last-status-change)))
        (or (and (or (eq doom--flycheck-err-cache doom--flycheck-cache)
                     (memq flycheck-last-status-change '(running not-checked)))
                 doom--flycheck-cache)
            (and (setq doom--flycheck-err-cache flycheck-current-errors)
                 (setq doom--flycheck-cache
                       (let ((fe (doom-ml-flycheck-count 'error))
                             (fw (doom-ml-flycheck-count 'warning)))
                         (concat
                          (if fe (propertize (format " •%d " fe)
                                             'face (if active
                                                       'doom-flycheck-error
                                                     'mode-line)))
                          (if fw (propertize (format " •%d " fw)
                                             'face (if active
                                                       'doom-flycheck-warning
                                                     'mode-line))))))))))

    (defun *buffer-position ()
      "A more vim-like buffer position."
      (let ((start (window-start))
            (end (window-end))
            (pend (point-max)))
        (if (and (= start 1)
                 (= end pend))
            ":All"
          (cond ((= start 1) ":Top")
                ((= end pend) ":Bot")
                (t (format ":%d%%%%" (/ end 0.01 pend)))))))

    (defun my-mode-line (&optional id)
      `(:eval
        (let* ((active (eq (selected-window) mode-line-selected-window))
               (lhs (list (propertize " " 'display (if active mode-line-bar mode-line-inactive-bar))
                          (*flycheck)
                          " "
                          (*buffer-path)
                          (*buffer-name)
                          " "
                          (*buffer-state)
                          ,(if (eq id 'scratch) '(*buffer-pwd))))
               (rhs (list (*buffer-encoding-abbrev) "  "
                          (*vc)
;;                          " "
;;                          (when persp-curr persp-modestring)
                          " " (*major-mode) "  "
                          (propertize
                           (concat "(%l,%c) " (*buffer-position))
                           'face (if active 'mode-line-2))))
               (middle (propertize
                        " " 'display `((space :align-to (- (+ right right-fringe right-margin)
                                                           ,(1+ (string-width (format-mode-line rhs)))))))))
          (list lhs middle rhs))))

    (setq-default mode-line-format (my-mode-line)))

(use-package pass
:ensure t)

(use-package auth-password-store
  :ensure t
  :config
  (auth-pass-enable))

(delete-selection-mode)
(global-set-key (kbd "RET") 'newline-and-indent)

(use-package rebox2
:ensure t
:config
(rebox-mode) 1)
