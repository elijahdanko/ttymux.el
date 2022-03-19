;;; ttymux.el --- Emacs vanilla Tmux switcher  -*- lexical-binding: t -*-
;;
;; Copyright (c) 2022 Elijah Danko
;;
;; Author: Illia A. Danko <me@eli.net>
;; URL: https://github.com/elijahdanko/ttymux.el
;; Created: February 19, 2022
;; Keywords: convenience, terminals, tmux, window, pane, navigation, integration
;; Package-Requires: ((emacs "24") (projectile "2.0.0"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Tmux workflow goodies.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;;; Tmux integration (See tmux.conf for details).
;; Feature added (https://github.com/tmux/tmux/issues/2904).
;;
;; Minimal tmux.conf:
;; unbind C-b
;; set -g prefix C-q
;; bind C-q send-prefix
;; is_emacs='echo "#{pane_current_command}" | grep -iqE "emacs"'
;; is_last_pane='echo "#{window_panes}" | grep -qwE "1"'
;; bind-key -T prefix % if-shell "$is_emacs" "send-prefix ; send-keys %" "split-window -h -c \"#{pane_current_path}\""
;; bind-key -T prefix c if-shell "$is_emacs" "send-prefix ; send-keys c" "new-window -c \"#{pane_current_path}\""
;; bind -Temacs-keys o if-shell "$is_emacs" "send C-x; send" "select-pane -t :.+"
;; bind -Temacs-keys 1 { kill-pane -a; send C-x; send }
;; bind -Temacs-keys Any { send C-x; send }
;; bind -Troot C-x switch-client -Temacs-keys

(require 'projectile)

(defcustom ttymux-pane-directory 'project
  "Advice tmux to choose a directory to open a pane."
  :type '(choice (const :tag "Project directory" project)
                 (const :tag "Active buffer path" buffer)
                 (const :tag "Home folder" home)))

(defvar ttymux-prefix-key "C-q"
  "Tmux prefix key.")

(defvar ttymux-new-tmux-tab-key "c"
  "Create a new Tmux tab key.")

(defvar ttymux-split-window-horizonatly "%"
  "Split Tmux window horizontally.")

(defvar ttymux-fallback-path "~"
  "Tmux pane path be used as a last resort.")

(defun ttymux--current-dir (mode)
  (pcase mode
    ('dired-mode (dired-current-directory))
    (_ default-directory)))

(defun ttymux--pane-path ()
  (pcase ttymux-pane-directory
    ('project (or (projectile-project-root)
                  (ttymux--current-dir major-mode)
                  ttymux-fallback-path))
    ('buffer (or (ttymux--current-dir major-mode)
                 ttymux-fallback-path))
    (_ ttymux-fallback-path)))

(defun ttymux--create-tmux-tab ()
  "Create a new Tmux tab."
  (interactive)
  (ignore-errors (call-process "tmux" nil nil nil "new-window" "-c"
                               (ttymux--pane-path))))

(defun ttymux--split-tmux-window-horiz ()
  "Split Tmux window horizontally."
  (interactive)
  (ignore-errors (call-process "tmux" nil nil nil "split-window" "-h" "-c"
                               (ttymux--pane-path))))

(defun ttymux--shell-command-equal (shell-cmd value)
  (string-equal value (string-trim (shell-command-to-string shell-cmd))))

(defun ttymux--tmux-other-window ()
  "Circle over Emacs windows, if the last window switch to the
next tmux pane if any."
  (interactive)
  (cond
   ((eq (next-window) (get-buffer-window))
    (ignore-errors (call-process "tmux" nil nil nil "select-pane" "-t" ":.+")))
   ((and (not (window-in-direction 'right))
         (not (window-in-direction 'below))
         (or (ttymux--shell-command-equal "tmux display-message -p \"#{pane_at_right}\"" "1")
             (ttymux--shell-command-equal "tmux display-message -p \"#{pane_at_left}\"" "1")
             (not (ttymux--shell-command-equal "tmux display-message -p \"#{window_panes}\"" "1"))))
    (other-window 1)
    (ignore-errors (call-process "tmux" nil nil nil "select-pane" "-t" ":.+")))
   (t (other-window 1))))

(defvar ttymux-mode-hook nil
  "Run after ttymux-mode turned on.")

(defun ttymux--mode-on ()
  "Override default keys. Run hooks."
  (let ((new-tmux-tab-key (concat ttymux-prefix-key
                                  " "
                                  ttymux-new-tmux-tab-key))
        (split-tmux-win-hor-key (concat ttymux-prefix-key
                                        " "
                                        ttymux-split-window-horizonatly)))
    (global-set-key (kbd ttymux-prefix-key) nil)
    (global-set-key (kbd new-tmux-tab-key) #'ttymux--create-tmux-tab)
    (global-set-key (kbd split-tmux-win-hor-key) #'ttymux--split-tmux-window-horiz)
    (global-set-key [remap other-window] #'ttymux--tmux-other-window))
  (run-hooks 'ttymux-mode-hook))

(defun ttymux--mode-off ())

;;;###autoload
(define-minor-mode ttymux-mode
  "Switch between Emacs and Tmux using vanilla Emacs shortcuts,
such as C-x o and C-x 1."
  :lighter " TTYMUX"
  (if ttymux-mode
      (ttymux--mode-on)
    (ttymux--mode-off)))

(provide 'ttymux)

;;; ttymux.el ends here
