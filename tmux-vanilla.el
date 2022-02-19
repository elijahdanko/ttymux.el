;;; tmux-vanilla.el --- Emacs vanilla Tmux switcher  -*- lexical-binding: t -*-
;;
;; Copyright (c) 2022 Elijah Danko
;;
;; Author: Illia A. Danko <me@eli.net>
;; URL: https://github.com/elijahdanko/tmux-vanilla.el
;; Created: February 19, 2022
;; Keywords: convenience, terminals, tmux, window, pane, navigation, integration
;; Package-Requires: ((dired "7.17") (emacs "24"))
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
;; bind -Temacs-keys 1 if-shell "$is_last_pane" "send C-x; send" "resize-pane -Z"
;; bind -Temacs-keys Any { send C-x; send }
;; bind -Troot C-x switch-client -Temacs-keys


(defvar tmux-vanilla-prefix-key "C-q"
  "Tmux prefix key.")

(defvar tmux-vanilla-new-tmux-tab-key "c"
  "Create a new Tmux tab key.")

(defvar tmux-vanilla-split-window-horizonatly "%"
  "Split Tmux window horizontally.")

(defun tmux-vanilla--current-dir (mode)
  (pcase mode
    ('dired-mode (dired-current-directory))
    (_ default-directory)))

(defun tmux-vanilla--create-tmux-tab ()
  "Create a new Tmux tab."
  (interactive)
  (ignore-errors (call-process "tmux" nil nil nil "new-window" "-c"
                               (tmux-vanilla--current-dir major-mode))))

(defun tmux-vanilla--split-tmux-window-horiz ()
  "Split Tmux window horizontally."
  (interactive)
  (ignore-errors (call-process "tmux" nil nil nil "split-window" "-h" "-c"
                               (tmux-vanilla--current-dir major-mode))))

(defun tmux-vanilla--tmux-other-window ()
  "Switch to the next window if opened, otherwise select a next
tmux pane."
  (interactive)
  (if (eq (next-window) (get-buffer-window))
      (ignore-errors (call-process "tmux" nil nil nil "select-pane" "-t" ":.+"))
    (other-window 1)))

(defvar tmux-vanilla-mode-hook nil
  "Run after tmux-vanilla-mode turned on.")

(defun tmux-vanilla--mode-on ()
  "Override default keys. Run hooks."
  (let ((new-tmux-tab-key (concat tmux-vanilla-prefix-key
                                  " "
                                  tmux-vanilla-new-tmux-tab-key))
        (split-tmux-win-hor-key (concat tmux-vanilla-prefix-key
                                        " "
                                        tmux-vanilla-split-window-horizonatly)))
    (global-set-key (kbd tmux-vanilla-prefix-key) nil)
    (global-set-key (kbd new-tmux-tab-key) #'tmux-vanilla--create-tmux-tab)
    (global-set-key (kbd split-tmux-win-hor-key) #'tmux-vanilla--split-tmux-window-horiz)
    (global-set-key [remap other-window] #'tmux-vanilla--tmux-other-window))
  (run-hooks 'tmux-vanilla-mode-hook))

(defun tmux-vanilla--mode-off ())

;;;###autoload
(define-minor-mode tmux-vanilla-mode
  "Switch between Emacs and Tmux using vanilla Emacs shortcuts,
such as C-x o and C-x 1."
  :lighter " TMUX"
  (if tmux-vanilla-mode
      (tmux-vanilla--mode-on)
    (tmux-vanilla--mode-off)))

(provide 'tmux-vanilla)

;;; tmux-vanilla.el ends here
