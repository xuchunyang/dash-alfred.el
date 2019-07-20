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
;;
;; See README on https://github.com/xuchunyang/dash-alfred.el

;;; Code:

(require 'dom)                          ; Added in Emacs 25.1

(defgroup dash-alfred nil
  "Search Dash documentation via Dash-Alfred-Workflow."
  :group 'external)

(defcustom dash-alfred-workflow
  (car
   (file-expand-wildcards
    "~/Library/Application Support/Alfred/Alfred.alfredpreferences/workflows/user.workflow.*/dashAlfredWorkflow"))
  "Path to dashAlfredWorkflow."
  :group 'dash-alfred
  :type 'string)

(defun dash-alfred-workflow-check ()
  "Ensure dashAlfredWorkflow is available."
  (unless (and dash-alfred-workflow
               (file-exists-p dash-alfred-workflow))
    (user-error "Can't find dashAlfredWorkflow")))

(defun dash-alfred-workflow-parse-output ()
  "Parse the output of dashAlfredWorkflow."
  (cl-loop for i from 0
           for item in (dom-children (libxml-parse-xml-region
                                      (point-min) (point-max)))
           for title = (dom-text (dom-child-by-tag item 'title))
           for subtitle = (dom-text
                           (car (last (dom-by-tag item 'subtitle))))
           collect (list title subtitle i)))


;;; * Helm

(declare-function helm "helm")
(declare-function helm-make-source "helm-source")
(defvar helm-pattern)

(defun dash-alfred-helm-candidates ()
  "Build helm candidates."
  (with-temp-buffer
    (if (zerop (call-process dash-alfred-workflow nil t nil helm-pattern))
        (mapcar
         (pcase-lambda (`(,title ,subtitle ,i))
           (cons (concat title "\n" subtitle) i))
         (dash-alfred-workflow-parse-output))
      (list "dashAlfredWorkflow failed:"
            (buffer-string)))))

(defvar dash-alfred-helm-actions
  `(("Open in Dash" .
     ,(lambda (i)
        (call-process "open" nil nil nil "-g"
                      (format "dash-workflow-callback://%d" i)))))
  "Actions for `dash-alfred-helm'.")

;;;###autoload
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
     :requires-pattern 1)
   :buffer "*helm dash alfred*"))


;;; * Ivy

(declare-function ivy-read "ivy")

;;;###autoload
(defun dash-alfred-ivy ()
  "Search Dash Documentation with Ivy."
  (interactive)
  (dash-alfred-workflow-check)
  (require 'ivy)
  (ivy-read
   "Search Dash: "
   (lambda (str)
     (with-temp-buffer
       (if (zerop (call-process dash-alfred-workflow nil t nil str))
           (mapcar
            (pcase-lambda (`(,title ,subtitle ,i))
              (propertize (concat title " " subtitle) 'i i))
            (dash-alfred-workflow-parse-output))
         (list
          "Error: dashAlfredWorkflow fails"
          ""
          (split-string (buffer-string) "\n")))))
   :dynamic-collection t
   :action (lambda (x)
             (call-process "open" nil nil nil "-g"
                           (format "dash-workflow-callback://%d"
                                   (get-text-property 0 'i x))))))

(provide 'dash-alfred)
;;; dash-alfred.el ends here
