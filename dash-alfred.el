;;; dash-alfred.el --- Search Dash documentation via Dash-Alfred-Workflow  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Xu Chunyang

;; Author: Xu Chunyang
;; Homepage: https://github.com/xuchunyang/dash-alfred.el
;; Package-Requires: ((emacs "25.1"))
;; Keywords: docs
;; Version: 0
;; Created: 2019-07-06

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Search Dash documentation via Dash-Alfred-Workflow.

;;; Code:

(require 'dom)

(defvar dash-alfred-workflow
  (car (file-expand-wildcards
        "~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/user.workflow.*/dashAlfredWorkflow"))
  "Path to dashAlfredWorkflow.")

(defun dash-alfred-workflow-check ()
  (unless (and dash-alfred-workflow
               (file-exists-p dash-alfred-workflow))
    (user-error "Can't find dashAlfredWorkflow, is Dash-Alfred-Workflow installed?")))

;;; * Helm
(declare-function helm "helm")
(declare-function helm-make-source "helm-source")
(defvar helm-pattern)

(defun dash-alfred-helm-candidates ()
  (with-temp-buffer
    (if (zerop (call-process dash-alfred-workflow nil t nil helm-pattern))
        (cl-loop for i from 0
                 for item in (dom-children (libxml-parse-xml-region (point-min) (point-max)))
                 for title = (dom-text (dom-child-by-tag item 'title))
                 for subtitle = (dom-text (car (last (dom-by-tag item 'subtitle))))
                 collect (cons (concat title "\n" subtitle) i))
      (list "dashAlfredWorkflow failed:"
            (buffer-string)))))

(defvar dash-alfred-helm-actions
  `(("Open" .
     ,(lambda (i)
        (call-process "open" nil nil nil "-g" (format "dash-workflow-callback://%d" i))))))

(defun dash-alfred-helm ()
  "Search Dash Documentation with Helm."
  (interactive)
  (dash-alfred-workflow-check)
  (require 'helm)
  (helm
   :sources
   (helm-make-source "Dash-Alfred" 'helm-source-sync
     :candidates #'dash-alfred-helm-candidates
     :action dash-alfred-helm-actions
     :multiline t
     :volatile t
     :match #'identity
     :nohighlight t
     :requires-pattern 1)))

(provide 'dash-alfred)
;;; dash-alfred.el ends here