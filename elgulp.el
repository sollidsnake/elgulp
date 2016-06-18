;; author: Jesse Nazario <jessenzr@gmail.com>
;; code hosted on https://github.com/sollidsnake/elgulp
;; licensed under apache 2.0


(define-minor-mode elgulp-mode
  "When activated, execute elgulp task automatically on save"
  :init-value nil
  :lighter "elgulp"
  :global t)

(defvar elgulp-output-buffer "*elgulp-output*"
  "Name of the output buffer")

(defvar elgulp-config-file "gulpfile.js"
  "Name of gulp configuration file")

(defcustom elgulp-path "gulp"
  "Location of gulp executable"
  :group 'elgulp)

(make-variable-buffer-local
 (defcustom elgulp-tasks-autosave t
   "Tasks to be run on autosave when `elgulp-mode' is activated

t will run all tasks
if this variable is a list, execute all tasks on list
nil won't run anything"
   :group 'elgulp))

(defcustom elgulp-display-output-buffer nil
  "t if you want to display a buffer with the output of gulp command. nil if you don't")

(defun elgulp--find-gulp-file (&optional destiny-dir)
  "Searches for gulpfile's directory"
  (let ((dir default-directory))
    
    (when (stringp destiny-dir)
      (setq dir destiny-dir))

    (when (stringp dir)
      (locate-dominating-file
       dir
       (lambda (parent) (directory-files parent nil "gulpfile.js"))))))

(defun elgulp--format-tasks (tasks)
  "Returns tasks formated in a list"
  (if tasks
      (let ((tasks (split-string tasks "\n")))
        (delete (car (last tasks)) tasks))
    '("a"))
  )

(defun elgulp--get-tasks ()
  "Retrieve tasks using command gulp --tasks-simple"
  (let ((default-directory (elgulp--find-gulp-file)))
    (when (stringp default-directory)
     (elgulp--format-tasks (shell-command-to-string
                            (concat elgulp-path " --tasks-simple"))))))

(defun elgulp-execute-task (task)
  "Execute task"
  (interactive
   (list (completing-read "Execute task: " (elgulp--get-tasks))))

  (call-process-shell-command (concat elgulp-path " " task)
                              nil elgulp-output-buffer)

  (when elgulp-display-output-buffer
    (let ((current-buffer-tmp (current-buffer)))
      (pop-to-buffer elgulp-output-buffer)
      (pop-to-buffer current-buffer-tmp))))


(defun elgulp--get-tasks-from-config ()
  "Analyse variable `elgulp-tasks-autosave' and returns the appropriate list"
  (cond
   ((equal elgulp-tasks-autosave t)
    (elgulp--get-tasks))

   ((listp elgulp-tasks-autosave)
    elgulp-tasks-autosave)

   ((equal elgulp-tasks-autosave nil)
    nil)))

(defun elgulp--execute-several-tasks (&optional tasks)
  "Execute tasks in `elgulp-tasks-autosave' list or argument"
  (when (not tasks)
    (setq tasks (elgulp--get-tasks-from-config)))

  (when tasks
    (elgulp-execute-task
     (mapconcat 'identity tasks " "))))

(defun elgulp-execute-task-if-activated ()
  "This function, called by `after-save-hook', checks if elgulp-mode
is active, and if so, it executes automatically tasks on
`elgulp-tasks-autosave'every time you save the file"
  (when elgulp-mode
    (elgulp--execute-several-tasks)))


(add-hook 'after-save-hook 'elgulp-execute-task-if-activated)

(provide 'elgulp)
