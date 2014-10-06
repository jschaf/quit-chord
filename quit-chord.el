;;; quit-chord.el --- quit everything with a key-chord

;; Copyright (C) 2014 Joe Schafer

;; Author: Joe Schafer <joe@jschaf.com>
;; Version: 0.1
;; Keywords: convenience
;; Package-Requires: ((key-chord) (smartrep))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Quit all diaglogs in Emacs with the same key-chord.
;;
;; See documentation on https://github.com/jschaf/quit-chord

;;; Code:

(require 'key-chord)
(require 'smartrep)

(eval-when-compile
  (require 'evil nil t))

(defgroup quit-chord nil
  "Quit all dialogs and modes in Emacs with one key-chord."
  :group 'quit-chord
  :prefix 'quit-chord-)

(defcustom quit-chord-key-1 "j"
  "The first key in the quit key chord."
  :type 'key-sequence
  :group 'quit-chord)

(defcustom quit-chord-key-2 "k"
  "The second key in the quit key chord."
  :type 'key-sequence
  :group 'quit-chord)

(defcustom quit-chord-delay 0.15
  "Max time delay between two presses to be a key-chord."
  :type 'float
  :group 'quit-chord)

(defcustom quit-chord-enabled-hook nil
  "Called after function `quit-chord-mode' is turned on."
  :type 'hook
  :group 'quit-chord)

(defcustom quit-chord-disabled-hook nil
  "Called after function `quit-chord-mode' is turned off."
  :type 'hook
  :group 'quit-chord)

;;;###autoload
(defun quit-chord ()
  "Functionality for escaping generally."
  (interactive)

  (cond
   ;; If we're in one of the evil states return to the normal-state
   ((and (boundp 'evil-mode)
         (or (evil-insert-state-p)
             (evil-replace-state-p)
             (evil-operator-state-p)
             (evil-visual-state-p)))
    (evil-force-normal-state))

   ((window-minibuffer-p)
    (abort-recursive-edit))

   ((string-prefix-p "*magit-key" (buffer-name))
    (magit-key-mode-command nil))

   (t (keyboard-quit))))

;; Exit isearch by pressing a key-chord, see
;; http://stackoverflow.com/questions/20926215
(defun quit-chord-isearch-exit-chord-worker (&optional arg)
  (interactive "p")
  ;; delete the initial `quit-chord-key-1' and accept the search
  (isearch-delete-char)
  (isearch-exit))

(defun quit-chord-isearch-exit-chord (arg)
  (interactive "p")
  ;; TODO: why do we need this?
  (isearch-printing-char)
  (eval-when-compile
    (require 'smartrep))
  ;; Manually signal quit because using `keyboard-quit' displays
  ;; "quit" in the echo-area, hiding the search text if you press 'j'
  ;; and another character besides 'k' in rapid succession.
  (run-at-time quit-chord-delay nil '(lambda () (signal 'quit nil)))
  (condition-case nil
    (smartrep-read-event-loop
      `((,quit-chord-key-1 . quit-chord-isearch-exit-chord-worker)
        (,quit-chord-key-2 . quit-chord-isearch-exit-chord-worker)))
    (quit nil)))

(defun quit-chord--init ()
  "Initialize the keymaps for quit-chord."

  (key-chord-define-global (kbd (concat quit-chord-key-1 quit-chord-key-2))
                           'quit-chord)

  (define-key isearch-mode-map quit-chord-key-1
    'quit-chord-isearch-exit-chord)

  (define-key isearch-mode-map quit-chord-key-2
    'quit-chord-isearch-exit-chord)

  ;; Hack for exiting `y-or-no-p'.  It's impossible to use normal
  ;; keybindings while `y-or-no-p' is executing.  It only responds to
  ;; a specific set of commands which are listed in the `y-or-no-p'
  ;; doc string.  So, we'll just bind the second keypress of our quit
  ;; key-chord to 'quit
  (define-key query-replace-map quit-chord-key-2 'quit))


;;;###autoload
(define-minor-mode quit-chord-mode
  "Toggle quit-chord mode."
  :init-value nil
  :lighter "Quit"
  :group 'quit-chord
  (if quit-chord-mode
      (progn
        (key-chord-mode 1)
        (quit-chord--init)
        (run-hooks 'quit-chord-enabled-hook))
    (run-hooks 'quit-chord-disabled-hook)))

;;;###autoload
(defun turn-on-quit-chord-mode ()
  "Turn on `quit-chord-mode'."
  (interactive)
  (quit-chord-mode 1))

;;;###autoload
(define-globalized-minor-mode quit-chord-global-mode
  quit-chord-mode
  turn-on-quit-chord-mode
  :group 'quit-chord)

(provide 'quit-chord)
;;; quit-chord.el ends here
