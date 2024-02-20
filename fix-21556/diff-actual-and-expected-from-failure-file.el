(defun delete-line-matching-regexp (regexp)
  (interactive "sInsert regexp: ")
  (search-forward-regexp regexp)
  (move-beginning-of-line 1)
  ;; kill line including newline
  (setq kill-whole-line 1)
  (kill-line)
  ;; revert kill-whole-line
  (setq kill-whole-line nil)            
)

(defun normalise-current-json()
  ;; add new line in between "dimensions"
  (beginning-of-buffer)
  (replace-string "dimensions" "
dimensions")
  (beginning-of-buffer)
  (replace-string "=" ":")
  ;; surround strings with double quotes
  (beginning-of-buffer)
  (replace-regexp "\\([a-zA-Z_]+\\)" "\"\\1\"")
  ;; split final ]] in ]\n]
  (beginning-of-line)
  (replace-string "]]" "]
]")
  ;; prepose { to dimensions beginning
  (beginning-of-buffer)
  (replace-string "\"dimensions\"" "{\"dimensions\"")
  ;; postpose } to dimensions end, in all but last line
  (beginning-of-buffer)
  (replace-regexp "\\(}]\\), $" "\\1},")
    ;; postpose } to dimensions end, in last line
  (end-of-buffer)
  (previous-line 2)
  (replace-regexp "\\(}]\\)$" "\\1}")
)

(defun trim-beginning-and-end-from-test-stacktrace()
  ;; removes the head of the trace
  (let ((beg (point))) (search-forward-regexp "\\[ERROR\\]   ExtensibleLoadManagerImplTest.testGetMetrics:[0-9]+ Sets differ: expected ") (delete-region beg (point)))
  ;; removes the tail of the trace
  (search-forward "[INFO]")
  (move-beginning-of-line 1)
  (let ((beg (point))) (end-of-buffer) (delete-region beg (point)))
  (save-buffer)
  (kill-buffer)
  )

(defun fix-21566-test-diff (file)
  (interactive "fGimme the file containing the failure")
  (setq tmp-failure-file  (replace-regexp-in-string ".txt" "-tmp.txt" file))
  (if (file-exists-p tmp-failure-file)
      (delete-file tmp-failure-file))
  (copy-file file tmp-failure-file)
  
  (find-file tmp-failure-file)
  (trim-beginning-and-end-from-test-stacktrace)
  
  (setq actual-file  (replace-regexp-in-string ".txt" "-actual.json" file))
  (if (file-exists-p actual-file)
      (delete-file actual-file))
  (copy-file tmp-failure-file actual-file)
  (find-file actual-file)
  (let ((beg (point))) (search-forward "but got ") (delete-region beg (point)))
  (normalise-current-json)
  (save-buffer)
  (kill-buffer)
  
  (setq expected-file  (replace-regexp-in-string ".txt" "-expected.json" file))
  (if (file-exists-p expected-file)
      (delete-file expected-file))
  (copy-file tmp-failure-file expected-file)
  (find-file expected-file)
  (search-forward "but got ")
  (backward-char 8)
  (let ((beg (point))) (end-of-buffer) (delete-region beg (point)))
  (normalise-current-json)
  (save-buffer)
  (kill-buffer)
  
  (delete-file tmp-failure-file)

  ;; run compare_metric.sh
  (setq path-to-failure-file  (concat (replace-regexp-in-string "/[a-zA-Z0-9_-]+.txt" "" file) "/"))
  (shell-command (concat path-to-failure-file "../compare_metric.sh " file))
 )
