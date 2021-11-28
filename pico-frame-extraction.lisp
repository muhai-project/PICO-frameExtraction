
(ql:quickload :xmls)
(ql:quickload :nlp-tools)
(ql:quickload :propbank-english)

(in-package :propbank-english)

;;;; Propbank Grammar
;;;; ----------------------------------------

(defparameter *restored-300-grammar*
  ;; The propbank grammar with cleaning parameter 300
  ;; is used by default. This could become a command
  ;; line option in the future.
  (restore
   (babel-pathname :directory '("grammars" "propbank-english" "grammars")
                   :name "propbank-grammar-ontonotes-ewt-cleaned-300"
                   :type "fcg")))


;;;; Xml parsing helper functions
;;;; ----------------------------------------


(defun find-all-nodes-based-on-name (top-node name)
  (find-all-nodes-based-on-name-aux top-node name nil))

(defun find-all-nodes-based-on-name-aux (top-node name nodes)
  (when (node-children-only top-node)
    (let ((name-found (find name (node-children-only top-node)
                            :key #'xmls::node-name :test #'string=)))
      (if name-found
        (push name-found nodes)
        (loop for node in (xmls::node-children top-node)
              append (find-all-nodes-based-on-name-aux node name nodes))))))

(defun node-children-only (node)
  (when (string= (type-of node) 'NODE)
    (let ((children nil))
      (loop for child in (xmls::node-children node)
            when (string= (type-of child) 'NODE)
            collect child))))

(defun text-children-only (node)
  (if (string= (type-of node) 'SIMPLE-TEXT-STRING)
    node
    (let ((children nil))
      (loop for child in (xmls::node-children node)
            when (string= (type-of child) 'SIMPLE-TEXT-STRING)
            collect child))))



(defparameter *xml-tree* nil
  "Subcutaneous rapid-acting insulin analogues for diabetic ketoacidosis")

(with-open-file (stream "/Users/katrien/Projects/PICO-frameExtraction/resources/CD011281v.2.0-Subcutaneous-rapid-acting-insulin-analogues-for-diabetic-ketoacidosis.rm5")
  (setf *xml-tree* (xmls:parse stream)))


;(find-all-nodes-based-on-name *xml-tree* "MAIN_TEXT")
        
;(find-all-nodes-based-on-name *xml-tree* "SUMMARY")

;(find-all-nodes-based-on-name *xml-tree* "SUMMARY_BODY")

;(find-all-nodes-based-on-name *xml-tree* "P")


(defparameter *extracted-text*
  ;;all textual material extracted from nodes with paragraph tag
  (loop for paragraph-node in (find-all-nodes-based-on-name *xml-tree* "P")
        append (text-children-only paragraph-node)))


;;;; Frame exraction
;;;; ----------------------------------------

(setf *penelope-host* "http://127.0.0.1:5000")

(defun utterance-length (string)
  (length (split-sequence:split-sequence #\Space string :remove-empty-subseqs t)
  ))

;(utterance-length "The treatment of DKA is traditionally accomplished by the administration of intravenous infusion of regular insulin that is initiated in the emergency department and continued in an intensive care unit or a high-dependency unit environment.")

(defun annotate-text (text cxn-inventory &key (silent t) (timeout 30))
  (cl-json:encode-json-alist-to-string
   `((:utterances . ,(loop with index = 0
                           for paragraph in text
                           for paragraph-sentences = (nlp-tools::get-penelope-sentence-tokens paragraph)
                           append (loop for utterance in paragraph-sentences
                                        when (> (utterance-length utterance) 1)
                                        collect
                                        (multiple-value-bind (solution cipn frame-set)
                                            (comprehend-and-extract-frames utterance :silent silent :cxn-inventory cxn-inventory :timeout timeout)
                                          (incf index)
                                          (format t "Utterance ~a: ~a (~a frames found)~%" index utterance (if (eql solution 'time-out)
                                                                                                             0
                                                                                                             (length (frames frame-set))))
                                          (unless (or (eql solution 'time-out)
                                                      (null (frames frame-set)))
                                            `((:frame-set  . ,(loop for frame in (frames frame-set)
                                                                    collect `((:frame-name . ,(frame-name frame))
                                                                              (:roles . ,(append
                                                                                          `(((:role . "V")
                                                                                             (:string . ,(fel-string (frame-evoking-element frame)))
                                                                                             (:indices . ,(indices (frame-evoking-element frame)))))
                                                                                          (loop for fe in (frame-elements frame)
                                                                                                collect `((:role . ,(fe-role fe))
                                                                                                          (:string . ,(fe-string fe))
                                                                                                          (:indices . ,(indices fe)))))))))
                                              (:utterance . ,utterance))))))))))

;;text annotation
;;(activate-monitor trace-fcg)
(defparameter *text-annotation* (annotate-text *extracted-text*
                                               *restored-300-grammar* :silent t :timeout 60))

;;write json to output file
(with-open-file (stream "/Users/katrien/Projects/PICO-frameExtraction/CD011281-v.2.0-frames.json" :direction :output :if-exists :overwrite)
  (format stream *text-annotation*))









