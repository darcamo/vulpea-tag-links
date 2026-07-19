;;; vulpea-tag-links.el --- Create links from tags.  -*- lexical-binding: t; -*-

;; Copyright (C) 2026 Darlan Cavalcante Moreira

;; Author: Darlan Cavalcante Moreira <darcamo@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "30.2") (vulpea "2.5.0"))
;; Homepage: https://github.com/darcamo/vulpea-tag-links

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is not part of GNU Emacs

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

;; Allow assigning an "ID tag" to a specific "Note X." When any other note is
;; tagged with the same ID tag, a link is automatically created from that note
;; to "Note X."

;; Example configuration:
;;
;; (require 'vulpea-tag-links)
;; (add-to-list 'vulpea-tag-links-id-tag-pairs (cons "Note1" "<id-of-Note1>"))
;; (add-to-list 'vulpea-tag-links-id-tag-pairs (cons "Note2" "<id-of-Note2>"))
;; (add-to-list 'vulpea-tag-links-id-tag-pairs (cons "Note3" "<id-of-Note3>"))

;;; Code:

(require 'vulpea)

(defvar vulpea-tag-links-id-tag-pairs nil
  "A list of `(ID-TAG . NOTE-ID)' pairs.

The `ID-TAG' represents the tag for the note, and `NOTE-ID' is the `ID'
of the note you want to link to. For example, if a note has the `ID'
`1234', and you want to link to it using the tag \"my-id-tag\", you
would add `(\"my-id-tag\" . \"1234\")' to the list.")


(defun vulpea-tag-links--get-id-from-id-tag (id-tag)
  "Get the note ID associated with the given ID-TAG."
  (cdr (assoc id-tag vulpea-tag-links-id-tag-pairs)))


(defun vulpea-tag-links--get-link-description (tag)
  "Get the description for the link based on the given TAG."
  (format "Link from tag '%s'" tag))


(defun vulpea-tag-links--extract-fn (_ note-data)
  "Update the links in NOTE-DATA to add links from tags.

NOTE-DATA is the plist of note data being processed.

The links in the returned note-data include original links plus any new
links derived from tags that match `vulpea-tag-links-id-tag-pairs'."
  (let* ((note-id (plist-get note-data :id))
         (tags (plist-get note-data :tags))
         (links (plist-get note-data :links)))
    (dolist (tag tags)
      (when-let*
          ((pair (assoc tag vulpea-tag-links-id-tag-pairs))
           (should-add-link (not (equal note-id (cdr pair))))) ; Avoid linking to self
        (push
         (list
          :dest (cdr pair)
          :type "tag"
          :pos 1
          :description (vulpea-tag-links--get-link-description tag))
         links)))

    ;; Returned note-data with updated links
    (plist-put note-data :links links)))


(defun vulpea-tag-links-register-extractor ()
  "Register the extractor function to be called when processing notes."
  (vulpea-db-register-extractor
   (make-vulpea-extractor
    :name 'vulpea-tag-links-extractor ; Symbol identifying the extractor
    :version 1 ; Schema version for migrations
    :priority 50 ; Execution order (lower = earlier)
    :requires-ast nil
    :worker-safe t
    :worker-lib 'vulpea-tag-links
    :extract-fn #'vulpea-tag-links--extract-fn) ; Extraction function
   ))


(defun vulpea-tag-links-unregister-extractor ()
  "Unregister the vulpea-tag-links extractor function."
  (vulpea-db-unregister-extractor 'vulpea-tag-links-extractor))


(provide 'vulpea-tag-links)
;;; vulpea-tag-links.el ends here
