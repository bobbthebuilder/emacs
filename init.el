;; ====== BEGIN of init.el ========

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    Highly customizable emacs configuration file which works out of the  
;;    box. Copyright (C) 2016 Daniel Feist
;;
;;    This program is free software: you can redistribute it and/or modify
;;    it under the terms of the GNU General Public License as published by
;;    the Free Software Foundation, either version 3 of the License, or
;;    (at your option) any later version.
;;
;;    This program is distributed in the hope that it will be useful,
;;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;    GNU General Public License for more details.
;;
;;    You should have received a copy of the GNU General Public License
;;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ====================
;; cleanup before start
;; ====================
;; hide bars
(tool-bar-mode -1)
(scroll-bar-mode -1)
(menu-bar-mode -1)
;; hide welcome screen
(setq inhibit-startup-screen t)

;; ====
;; misc
;; ====
; make all "yes or no" prompts show "y or n" instead
(fset 'yes-or-no-p 'y-or-n-p)
; "filename [mode]" in title bar
(setq frame-title-format '("%f [mode: %m] @ " (getenv "HOSTNAME")))

;; =================================================
;; autoinstall additional, non-preinstalled packages
;; =================================================
(require 'cl)
(require 'package)

(setq cfg-var:packages '(
			 ;auto-dim-other-buffers
			 irony	
			 ;irony-eldoc
			 company
			 company-irony
			 flycheck-irony
			 magit
			 markdown-mode
			 undo-tree
			 ;rainbow-delimiters
			 smooth-scrolling	
			 yasnippet))
       
(defun cfg:install-packages ()
  (let ((pkgs (remove-if #'package-installed-p cfg-var:packages)))
    (when pkgs
      (message "%s" "Emacs refresh packages database...")
      (package-refresh-contents)
      (message "%s" " done.")
      (dolist (p cfg-var:packages)
	(package-install p)))))

(add-to-list 'package-archives '("gnu" . "http://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives  '("melpa" . "http://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)

;; update package archives 
;(when (not package-archive-contents)
;  (package-refresh-contents))

(package-initialize)
(cfg:install-packages)

;; =====
;; modes 
;; =====
; turn on paren matching
(show-paren-mode t)
(setq show-paren-style 'expression)

;; ============
;; company mode
;; ============ 
(add-hook 'after-init-hook 'global-company-mode)

;; ==========
;; irony-mode
;; ==========
;; please note: run M-x irony-install-server on the first run  
(add-hook 'c++-mode-hook 'irony-mode)
(add-hook 'c-mode-hook 'irony-mode)
;(add-hook 'objc-mode-hook 'irony-mode)
;; replace the `completion-at-point' and `complete-symbol' bindings in
;; irony-mode's buffers by irony-mode's function
(defun my-irony-mode-hook ()
  (define-key irony-mode-map [remap completion-at-point]
    'irony-completion-at-point-async)
  (define-key irony-mode-map [remap complete-symbol]
    'irony-completion-at-point-async))
(add-hook 'irony-mode-hook 'my-irony-mode-hook)
(add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
(add-hook 'irony-mode-hook 'company-irony-setup-begin-commands)

;; enable C++17 support in clang 
(setq irony-additional-clang-options '("-std=c++1z"))

(eval-after-load 'company 
  '(add-to-list 'company-backends 'company-irony))

;; =============
;; eldoc-mode
;; =============
;(add-hook 'irony-mode-hook 'irony-eldoc)

;; =============
;; flycheck-mode
;; =============

(add-hook 'c++-mode-hook 'flycheck-mode)
(add-hook 'c-mode-hook 'flycheck-mode)
(eval-after-load 'flycheck 
  '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))
   
; Enable C++11 support for clang
(add-hook 'c++-mode-hook (lambda () (setq flycheck-clang-language-standard "c++11")))

;; ==================================
;; enable semantic-mode
;; ==================================
(semantic-mode 1)

;; ==============
;; yasnippet-mode
;; ==============
;(add-to-list 'load-path "~/emacs.d/yasnippet")
(yas-global-mode 1)

(defun check-expansion ()
  (save-excursion
    (if (looking-at "\\_>") 
	(backward-char 1)
      (if (looking-at "\\.") t
	(backward-char 1)
	(if (looking-at "->") t nil)))))

(defun do-yas-expand ()
  (let ((yas/fallback-behavior 'return-nil))
    (yas/expand)))

(defun tab-indent-or-complete ()
  (interactive)
  (if (minibufferp)
      (minibuffer-complete)
    (if (or (not yas/minor-mode)
            (null (do-yas-expand)))
        (if (check-expansion)
            (company-complete-common)
          (indent-for-tab-command)))))

(global-set-key [tab] 'tab-indent-or-complete)

;; ===================================================
;; make M-x compile smarter in order to guess language
;; ===================================================
(defvar compile-guess-command-table
  '((c-mode       . "gcc -Wall -g %s -o %s -lm")
    (c++-mode     . "g++ -Wall %s -o %s -std=c++1z")))

(defun compile-guess-command ()
  (let ((command-for-mode (cdr (assq major-mode
                                     compile-guess-command-table))))
    (if (and command-for-mode
             (stringp buffer-file-name))
        (let* ((file-name (file-name-nondirectory buffer-file-name))
               (file-name-sans-suffix (if (and (string-match "\\.[^.]*\\'"
                                                             file-name)
                                               (> (match-beginning 0) 0))
                                          (substring file-name
                                                     0 (match-beginning 0))
                                        nil)))
          (if file-name-sans-suffix
              (progn
                (make-local-variable 'compile-command)
                (setq compile-command
                      (if (stringp command-for-mode)
                          ;; Optimize the common case.
                          (format command-for-mode
                                  file-name file-name-sans-suffix)
                        (funcall command-for-mode
                                 file-name file-name-sans-suffix)))
                compile-command)
            nil))
      nil)))
      
;; Add the appropriate mode hooks.
(add-hook 'c-mode-hook       (function compile-guess-command))
(add-hook 'c++-mode-hook     (function compile-guess-command))

;; ==================================
;; enable auto-dim-other-buffers-mode
;; ==================================
;(add-hook 'after-init-hook (lambda ()
;  (when (fboundp 'auto-dim-other-buffers-mode)
;    (auto-dim-other-buffers-mode t))))

;; ==============================
;; enable rainbow delimiters mode
;; ==============================
;(add-hook 'prog-mode-hook #'rainbow-delimiters-mode)

;; =================
;; enable magit mode
;; =================
(add-to-list 'load-path "~/.emacs.d/site-lisp/magit/lisp")

(with-eval-after-load 'info
  (info-initialize)
  (add-to-list 'Info-directory-list
               "~/.emacs.d/site-lisp/magit/Documentation/"))

;; =============
;; markdown mode
;; =============
(autoload 'markdown-mode "markdown-mode"
  "Major mode for editing Markdown files" t)
(add-to-list 'auto-mode-alist '("\\.text\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.markdown\\'" . markdown-mode))
(add-to-list 'auto-mode-alist '("\\.md\\'" . markdown-mode))

;; ==============
;; undo-tree mode
;; ==============
(global-undo-tree-mode)

;; ================
;; smooth scrolling
;; ===============
;; Scroll line by line
(setq redisplay-dont-pause t)
;; number of lines at the top and bottom of a window.
(setq scroll-margin 2)
;; Controls if scroll commands move point to keep its screen position unchanged.
(setq scroll-preserve-screen-position nil)
;; four line at a time
(setq mouse-wheel-scroll-amount '(4 ((shift) . 4)))
;; accelerate scrolling
(setq mouse-wheel-progressive-speed 't)
;; scroll window under mouse
(setq mouse-wheel-follow-mouse 't)
;; keyboard scroll four line at a time
(setq scroll-step 4)
;; number of lines at the top and bottom of a window.
(setq smooth-scroll-margin 3)
(setq smooth-scroll-strict-margins 't)

;; ====================
;; custom key shortcuts
;; ====================
(global-set-key [f2] 'eshell)   
(global-set-key [f5] 'compile)

(global-set-key "\M-g" 'goto-line)

;; =======================
;; colorize modes by theme 
;; =======================

(deftheme df "Customizable color theme for Emacs24+")

(let ((class '((class color) (min-colors 89)))
      (background "black")
      (alt-background "#222")
      (strong "#eee")
      (bright "#eee")
      (normal "gray")
      (normal-bright "#3e3e3e")
      (faint "#888")
      (dark "#888")
      (faintest "#333")
      (very-dark "#333")
      (darkest "black")
      (contrast-background "#331133")
      (red-brightest "#ffbbbb")
      (red-bright "#f25a5a")
      (red "red")
      (red-dark "#5a0000")
      (red-darkest "#1a0000")
      (pink-brightest "#ffbfd7")
      (pink-brighter "#ff8fb7")
      (pink "#ff5f87")
      (pink-darker "#aa2255")
      (orange "#efc334")
      (yellow "#f6df92")
      (yellow-darker "#a86")
      (yellow-dark "#643")
      (green-bright "#dcf692")
      (green "#acfb5a")
      (green-darker "#77bb33")
      (cyan "#5af2ee")
      (turquoise "#3affa3")
      (malachite "#3aff83")
      (blue-bright "#dcdff2")
      (blue "#b2baf6")
      (blue-darker "#5555dd")
      (magenta-bright "#f09fff")
      (magenta "#c350ff")
      (magenta-dark "#34004A")
      (magenta-darkest "#1B0026")
      (violet "#78537A")
      (violet-darkest "#110011")
      (violet-red "#d020a7")
      )

  (custom-theme-set-faces
   'df

   ;; standard faces
   `(default ((,class (:inherit nil :stipple nil :background ,background :foreground "white" 
    :inverse-video nil :box nil :strike-through nil :overline nil :underline nil 
    :slant normal :weight normal :height 112 :width normal :foundry "Misc" :family "Fixed"))))
   `(bold ((,class (:weight bold))))
   `(italic ((,class (:slant italic))))
   `(bold-italic ((,class (:slant italic :weight bold))))
   `(underline ((,class (:underline t))))
   `(shadow ((,class (:foreground ,normal))))
   `(link ((,class (:foreground ,turquoise :underline t))))

   `(highlight ((,class (:inverse-video nil :background ,alt-background))))
   `(isearch ((,class (:foreground ,yellow :background ,background :inverse-video t))))
   `(isearch-fail ((,class (:background ,background :inherit font-lock-warning-face :inverse-video t))))
   `(match ((,class (:foreground ,blue :background ,background :inverse-video t))))
   `(lazy-highlight ((,class (:foreground ,cyan :background ,background :inverse-video t))))
   `(region ((,class (:background ,magenta-dark))))
   `(secondary-selection ((,class (:background ,alt-background))))
   `(trailing-whitespace ((,class (:background ,red :underline nil))))

   `(mode-line ((t (:foreground ,strong :background ,contrast-background))))
   `(mode-line-inactive ((t (:foreground ,yellow-dark :background ,violet-darkest :weight light :box nil :inherit (mode-line )))))
   `(mode-line-buffer-id ((t (:foreground ,yellow))))
   `(mode-line-emphasis ((,class (:foreground ,magenta))))
   `(which-func ((,class (:foreground ,blue :background nil :weight bold))))

   `(header-line ((,class (:inherit mode-line :foreground ,magenta :background nil))))
   `(minibuffer-prompt ((,class (:foreground ,blue))))
   `(fringe ((,class (:background ,alt-background))))
   `(cursor ((,class (:background ,green))))
   `(border ((,class (:background ,alt-background))))
   `(widget-button ((,class (:underline t))))
   `(widget-field ((,class (:background ,alt-background :box (:line-width 1 :color ,normal)))))

   `(success ((,class (:foreground ,green))))
   `(warning ((,class (:foreground ,orange))))
   `(error ((,class (:foreground ,red))))

   `(show-paren-match ((,class (:foreground ,pink :background nil :slant italic :weight bold))))
   `(show-paren-mismatch ((,class (:background ,background :inherit font-lock-warning-face :inverse-video t))))

   `(custom-variable-tag ((,class (:foreground ,blue))))
   `(custom-group-tag ((,class (:foreground ,blue))))
   `(custom-state-tag ((,class (:foreground ,green))))

   ;; general font lock faces
   `(font-lock-builtin-face ((,class (:foreground ,blue))))
   `(font-lock-comment-delimiter-face ((,class (:foreground ,yellow))))
   `(font-lock-comment-face ((,class (:foreground ,orange))))
   `(font-lock-constant-face ((,class (:foreground ,malachite))))
   `(font-lock-doc-face ((,class (:foreground ,magenta))))
   `(font-lock-doc-string-face ((,class (:foreground ,yellow))))
   `(font-lock-function-name-face ((,class (:foreground ,magenta-bright))))
   `(font-lock-keyword-face ((,class (:foreground ,cyan))))
   `(font-lock-negation-char-face ((,class (:foreground ,green))))
   `(font-lock-preprocessor-face ((,class (:foreground ,violet-red))))
   `(font-lock-regexp-grouping-backslash ((,class (:foreground ,cyan))))
   `(font-lock-regexp-grouping-construct ((,class (:foreground ,magenta))))
   `(font-lock-string-face ((,class (:foreground ,pink))))
   `(font-lock-type-face ((,class (:foreground ,blue))))
   `(font-lock-variable-name-face ((,class (:foreground ,yellow))))
   `(font-lock-warning-face ((,class (:weight bold :foreground ,red))))

   ;; ===================
   ;; mode specific faces
   ;; ===================
   	
   ;; asorted faces
   `(csv-separator-face ((,class (:foreground ,yellow))))
   `(border-glyph ((,class (nil))))
   `(gui-element ((,class (:background ,alt-background :foreground ,normal))))
   `(hl-sexp-face ((,class (:background ,alt-background))))
   `(highlight-80+ ((,class (:background ,alt-background))))
   `(rng-error-face ((,class (:underline ,red))))
   `(py-builtins-face ((,class (:foreground ,orange :weight normal))))

   ;; auto-dim-other-buffers 
   ;`(auto-dim-other-buffers-face ((,class (:background "#0c0c0c"))))

   ;; company
   `(company-preview ((,class (:foreground "darkgray" :underline t))))
   `(company-preview-common ((t (:inherit company-preview))))
   `(company-preview-search ((,class (:foreground ,darkest :background ,yellow))))
   `(company-tooltip ((,class (:background ,blue-darker :foreground "white"))))
   `(company-tooltip-common ((((type x)) (:inherit company-tooltip :weight bold))
      (t (:inherit company-tooltip))))
   `(company-tooltip-common-selection  ((((type x)) (:inherit company-tooltip-selection :weight bold))
      (t (:inherit company-tooltip-selection))))
   `(company-tooltip-selection ((,class (:background ,normal :foreground ,background))))
   `(company-scrollbar-bg ((,class (:background ,normal-bright))))
   `(company-scrollbar-fg ((,class (:background "darkgray"))))
   
   ;; compilation
   `(compilation-column-number ((,class (:foreground ,yellow))))
   `(compilation-line-number ((,class (:foreground ,yellow))))
   `(compilation-message-face ((,class (:foreground ,blue))))
   `(compilation-mode-line-exit ((,class (:foreground ,green))))
   `(compilation-mode-line-fail ((,class (:foreground ,red))))
   `(compilation-mode-line-run ((,class (:foreground ,blue))))
   `(compilation-info ((,class (:foreground ,turquoise))))

   ;; diff
   `(diff-added ((,class (:foreground ,green))))
   `(diff-changed ((,class (:foreground ,violet))))
   `(diff-removed ((,class (:foreground ,orange))))
   `(diff-header ((,class (:foreground ,cyan :background nil))))
   `(diff-file-header ((,class (:foreground ,blue :background nil))))
   `(diff-hunk-header ((,class (:foreground ,magenta))))
   `(diff-refine-removed ((,class (:inherit magit-diff-removed-highlight :foreground ,red-brightest))))
   `(diff-refine-added ((,class (:inherit magit-diff-added-highlight :foreground ,blue-bright))))

   ;; ediff
   `(ediff-even-diff-A ((,class (:foreground nil :background nil :inverse-video t))))
   `(ediff-even-diff-B ((,class (:foreground nil :background nil :inverse-video t))))
   `(ediff-odd-diff-A  ((,class (:foreground ,faint :background nil :inverse-video t))))
   `(ediff-odd-diff-B  ((,class (:foreground ,faint :background nil :inverse-video t))))

   ;; eldoc
   `(eldoc-highlight-function-argument ((,class (:foreground ,green :weight bold))))

   ;; erc (irc)
   `(erc-direct-msg-face ((,class (:foreground ,yellow))))
   `(erc-error-face ((,class (:foreground ,red))))
   `(erc-header-face ((,class (:foreground ,strong :background ,alt-background))))
   `(erc-input-face ((,class (:foreground ,yellow))))
   `(erc-current-nick-face ((,class (:foreground ,blue :weight bold))))
   `(erc-my-nick-face ((,class (:foreground ,blue))))
   `(erc-nick-default-face ((,class (:weight normal :foreground ,violet))))
   `(erc-nick-msg-face ((,class (:weight normal :foreground ,yellow))))
   `(erc-notice-face ((,class (:foreground ,blue-bright))))
   `(erc-pal-face ((,class (:foreground ,orange))))
   `(erc-prompt-face ((,class (:foreground ,blue))))
   `(erc-timestamp-face ((,class (:foreground ,cyan))))
   `(erc-keyword-face ((,class (:foreground ,green))))

   ;; eshell
   `(eshell-ls-archive ((,class (:foreground ,cyan :weight normal))))
   `(eshell-ls-backup ((,class (:foreground ,yellow))))
   `(eshell-ls-clutter ((,class (:foreground ,orange :weight normal))))
   `(eshell-ls-directory ((,class (:foreground ,blue :weight normal))))
   `(eshell-ls-executable ((,class (:foreground ,red :weight normal))))
   `(eshell-ls-missing ((,class (:foreground ,violet :weight normal))))
   `(eshell-ls-product ((,class (:foreground ,yellow))))
   `(eshell-ls-readonly ((,class (:foreground ,faintest))))
   `(eshell-ls-special ((,class (:foreground ,green :weight normal))))
   `(eshell-ls-symlink ((,class (:foreground ,magenta :weight normal))))
   `(eshell-ls-unreadable ((,class (:foreground ,normal))))
   `(eshell-prompt ((,class (:foreground ,green :weight normal))))

   ;; eval-sexp-fu
   `(eval-sexp-fu-flash ((,class (:background ,magenta-dark))))

   ;; fic-mode
   `(font-lock-fic-face ((,class (:background ,red :foreground ,red-darkest :weight bold))))

   ;; flycheck   
   `(flycheck-error-face ((t (:foreground ,red :background ,red-darkest :weight bold))))

   ;; git-gutter
   `(git-gutter:modified ((,class (:foreground ,violet :weight bold))))
   `(git-gutter:added ((,class (:foreground ,green :weight bold))))
   `(git-gutter:deleted ((,class (:foreground ,red :weight bold))))
   `(git-gutter:unchanged ((,class (:background ,yellow))))

   ;; git-gutter-fringe
   `(git-gutter-fr:modified ((,class (:foreground ,violet :weight bold))))
   `(git-gutter-fr:added ((,class (:foreground ,green :weight bold))))
   `(git-gutter-fr:deleted ((,class (:foreground ,red :weight bold))))

   ;; grep
   `(grep-context-face ((,class (:foreground ,faint))))
   `(grep-error-face ((,class (:foreground ,red :weight bold :underline t))))
   `(grep-hit-face ((,class (:foreground ,blue))))
   `(grep-match-face ((,class (:foreground nil :background nil :inherit match))))

   ;; highlight-symbol
   `(highlight-symbol-face ((,class (:background ,yellow-dark))))

   ;; icomplete
   `(icomplete-first-match ((,class (:foreground "white" :bold t))))

   ;; ido
   `(ido-subdir ((,class (:foreground ,magenta))))
   `(ido-first-match ((,class (:foreground ,yellow))))
   `(ido-only-match ((,class (:foreground ,green))))
   `(ido-indicator ((,class (:foreground ,red :background ,background))))
   `(ido-virtual ((,class (:foreground ,faintest))))

   ;; linum
   `(linum ((,class (:background ,alt-background))))

   ;; magit
   `(magit-branch ((,class (:foreground ,green))))
   `(magit-header ((,class (:inherit nil :weight bold))))
   `(magit-item-highlight ((,class (:inherit highlight :background nil))))
   `(magit-log-graph ((,class (:foreground ,faintest))))
   `(magit-log-sha1 ((,class (:foreground ,yellow))))
   `(magit-log-head-label-bisect-bad ((,class (:foreground ,red))))
   `(magit-log-head-label-bisect-good ((,class (:foreground ,green))))
   `(magit-log-head-label-default ((,class (:foreground ,yellow :box nil :weight bold))))
   `(magit-log-head-label-local ((,class (:foreground ,magenta :box nil :weight bold))))
   `(magit-log-head-label-remote ((,class (:foreground ,violet :box nil :weight bold))))
   `(magit-log-head-label-tags ((,class (:foreground ,cyan :box nil :weight bold))))
   `(magit-section-title ((,class (:foreground ,blue :weight bold))))

   ;; magit `next'
   `(magit-section ((,class (:inherit nil :weight bold))))
   `(magit-section-highlight ((,class (:foreground ,bright))))
   `(magit-section-heading ((,class (:foreground ,blue-bright))))
   `(magit-branch-local ((,class (:foreground ,turquoise))))
   `(magit-branch-remote ((,class (:foreground ,yellow))))
   `(magit-hash ((,class (:foreground "white"))))
   `(magit-diff-file-heading ((,class (:foreground ,yellow))))
   `(magit-diff-hunk-heading ((,class (:foreground ,magenta))))
   `(magit-diff-hunk-heading-highlight ((,class (:inherit magit-diff-hunk-heading :weight bold))))
   `(magit-diff-context ((,class (:foreground ,normal))))
   `(magit-diff-context-highlight ((,class (:inherit magit-diff-context :foreground ,bright))))
   `(magit-diff-added ((,class (:foreground ,blue))))
   `(magit-diff-added-highlight ((,class (:inherit magit-diff-added :weight bold))))
   `(magit-diff-removed ((,class (:foreground ,red-bright))))
   `(magit-diff-removed-highlight ((,class (:inherit magit-diff-removed :weight bold))))

   ;; markdown
   `(markdown-url-face ((,class (:inherit link))))
   `(markdown-link-face ((,class (:foreground ,blue :underline t))))
   `(markdown-header-face-1 ((,class (:inherit org-level-1))))
   `(markdown-header-face-2 ((,class (:inherit org-level-2))))
   `(markdown-header-face-3 ((,class (:inherit org-level-3))))
   `(markdown-header-face-4 ((,class (:inherit org-level-4))))
   `(markdown-header-delimiter-face ((,class (:foreground ,orange))))
   `(markdown-pre-face ((,class (:foreground "white"))))
   `(markdown-inline-code-face ((,class (:foreground "white"))))

   ;; mark-multiple
   `(mm/master-face ((,class (:inherit region :foreground nil :background nil))))
   `(mm/mirror-face ((,class (:inherit region :foreground nil :background nil))))

   ;; mic-paren
   `(paren-face-match ((,class (:foreground nil :background nil :inherit show-paren-match))))
   `(paren-face-mismatch ((,class (:foreground nil :background nil :inherit show-paren-mismatch))))
   `(paren-face-no-match ((,class (:foreground nil :background nil :inherit show-paren-mismatch))))

   ;; mmm-mode
   `(mmm-code-submode-face ((,class (:background ,alt-background))))
   `(mmm-comment-submode-face ((,class (:inherit font-lock-comment-face))))
   `(mmm-output-submode-face ((,class (:background ,alt-background))))

   ;; nrepl-eval-sexp-fu
   `(nrepl-eval-sexp-fu-flash ((,class (:background ,magenta-dark))))

   ;; nxml 
   `(nxml-name-face ((,class (:foreground unspecified :inherit font-lock-constant-face))))
   `(nxml-attribute-local-name-face ((,class (:foreground unspecified :inherit font-lock-variable-name-face))))
   `(nxml-ref-face ((,class (:foreground unspecified :inherit font-lock-preprocessor-face))))
   `(nxml-delimiter-face ((,class (:foreground unspecified :inherit font-lock-keyword-face))))
   `(nxml-delimited-data-face ((,class (:foreground unspecified :inherit font-lock-string-face))))

   ;; outline
   `(outline-3 ((,class (:inherit nil :foreground ,green))))
   `(outline-4 ((,class (:slant normal :foreground ,faint))))

   ;; parenface
   `(paren-face ((,class (:foreground ,faintest :background nil))))

   ;; powerline
   `(powerline-active1 ((t (:foreground ,normal :background ,contrast-background))))
   `(powerline-active2 ((t (:foreground ,normal :background ,alt-background))))

   ;; rainbow-delimiters 
   ;`(rainbow-delimiters-depth-1-face ((,class (:foreground ,normal))))
   ;`(rainbow-delimiters-depth-2-face ((,class (:foreground ,cyan))))
   ;`(rainbow-delimiters-depth-3-face ((,class (:foreground ,yellow))))
   ;`(rainbow-delimiters-depth-4-face ((,class (:foreground ,green))))
   ;`(rainbow-delimiters-depth-5-face ((,class (:foreground ,blue))))
   ;`(rainbow-delimiters-depth-6-face ((,class (:foreground ,normal))))
   ;`(rainbow-delimiters-depth-7-face ((,class (:foreground ,cyan))))
   ;`(rainbow-delimiters-depth-8-face ((,class (:foreground ,yellow))))
   ;`(rainbow-delimiters-depth-9-face ((,class (:foreground ,green))))
   ;`(rainbow-delimiters-unmatched-face ((,class (:foreground ,red))))

   ;; regex-tool
   `(regex-tool-matched-face ((,class (:foreground nil :background nil :inherit match))))
   `(regex-tool-matched-face ((,class (:foreground nil :background nil :inherit match))))

   ;; sh-script
   `(sh-heredoc ((,class (:foreground nil :inherit font-lock-string-face :weight normal))))
   `(sh-quoted-exec ((,class (:foreground nil :inherit font-lock-preprocessor-face))))

   ;; shr
   `(shr-link ((,class (:foreground ,blue :underline t))))

   ;; slime
   `(slime-highlight-edits-face ((,class (:foreground ,strong))))
   `(slime-repl-input-face ((,class (:weight normal :underline nil))))
   `(slime-repl-prompt-face ((,class (:underline nil :weight bold :foreground ,magenta))))
   `(slime-repl-result-face ((,class (:foreground ,green))))
   `(slime-repl-output-face ((,class (:foreground ,blue :background ,background))))

   ;; smart-mode-line
   `(sml/prefix ((,class (:foreground ,green-bright))))
   `(sml/folder ((,class (:foreground ,magenta-bright))))
   `(sml/filename ((,class (:foreground ,yellow))))
   `(sml/vc-edited ((,class (:foreground ,pink))))

   ;; term
   `(term-color-black ((,class (:background ,alt-background :foreground ,alt-background))))
   `(term-color-blue ((,class (:background ,blue :foreground ,blue))))
   `(term-color-cyan ((,class (:background ,cyan :foreground ,cyan))))
   `(term-color-green ((,class (:background ,malachite :foreground ,malachite))))
   `(term-color-magenta ((,class (:background ,magenta :foreground ,magenta))))
   `(term-color-red ((,class (:background ,red :foreground ,red))))
   `(term-color-white ((,class (:background ,contrast-background :foreground ,contrast-background))))
   `(term-color-yellow ((,class (:background ,yellow :foreground ,yellow))))

   ;; undo-tree
   `(undo-tree-visualizer-default-face ((,class (:foreground ,normal))))
   `(undo-tree-visualizer-current-face ((,class (:foreground ,green :weight bold))))
   `(undo-tree-visualizer-active-branch-face ((,class (:foreground ,red))))
   `(undo-tree-visualizer-register-face ((,class (:foreground ,yellow))))

   ;; web-mode
   `(web-mode-html-tag-face ((,class (:foreground ,bright))))
   `(web-mode-html-attr-name-face ((,class (:inherit font-lock-doc-face))))
   `(web-mode-doctype-face ((,class (:inherit font-lock-builtin-face))))

   ))

;;;###autoload
(when (and (boundp 'custom-theme-load-path) load-file-name)
  (add-to-list 'custom-theme-load-path
               (file-name-as-directory (file-name-directory load-file-name))))

;; Local Variables:
;; no-byte-compile: t
;; End:

(provide-theme 'df)

;; ====== END of init.el ========
