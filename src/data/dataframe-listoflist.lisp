;;; -*- mode: lisp -*-

;;; Time-stamp: <2014-02-12 08:52:30 tony>
;;; Creation:   <2009-03-12 17:14:56 tony>
;;; File:       dataframe-listoflist.lisp
;;; Author:     AJ Rossini <blindglobe@gmail.com>
;;; Copyright:  (c) 2009--, AJ Rossini.  MIT License, see README.mit
;;;             in the top level directory.
;;; Purpose:    Instance of dataframe with the storage done using
;;;             LISTOFLIST data storage found in the corresponding
;;;             LISP package.

;;; What is this talk of 'release'? Klingons do not make software
;;; 'releases'.  Our software 'escapes', leaving a bloody trail of
;;; designers and quality assurance people in its wake.

(in-package :cls-dataframe)

;;; DATAFRAME-LISTOFLIST
;;; 
;;; example/implementation of using listoflist datastructures for
;;; dataframe storage.

(defclass dataframe-listoflist (dataframe-like)
  ((store :initform nil
	  :initarg :storage
	  :type list
	  :accessor dataset
	  :documentation "Data storage: typed as listoflist."))
  (:documentation "Implementation of dataframe-like objects
  using list-of-list data storage."))

(defmethod make-dataframe2 ((data dataframe-listoflist)
			    &key vartypes varlabels caselabels doc 
			      ;; (vartypes sequence)
			      ;; (varlabels sequence)
			      ;; (caselabels sequence)
			      ;; (doc string)
			      )
  (check-dataframe-params data vartypes varlabels caselabels doc)
  (build-dataframe 'dataframe-listoflist))

(defmethod nrows ((df dataframe-listoflist))
  "specializes on inheritance from listoflist in lisp-matrix."
  (length (dataset df)))

(defmethod nrows ((df list))
  "specializes on inheritance from listoflist in lisp-matrix."
  (length df))

(defmethod ncols ((df dataframe-listoflist))
  "specializes on inheritance from listoflist. This approach assumes
that the list of list is in a coherent form, that is that it maps
naturally to a rectangular array."
  (length (elt (dataset df) 0)))

(defmethod ncols ((df list))
  "specializes on inheritance from listoflist. This approach assumes
that the list of list is in a coherent form, that is that it maps
naturally to a rectangular array."
  (length (elt df 0)))

(defmethod nvars ((df dataframe-listoflist))
  "specializes on inheritance from listoflist. This approach assumes
that the list of list is in a coherent form, that is that it maps
naturally to a rectangular array."
  (length (elt (dataset df) 0)))

(defmethod nvars ((pre-df list))
  "specializes on inheritance from listoflist. This approach assumes
that the list of list is in a coherent form, that is that it maps
naturally to a rectangular array."
  (length (elt pre-df 0)))


;; For XREF and SETF XREF, we have the following list of list consideration:
;; (list (list 11 12 13 14)
;;       (list 21 22 23 24))
;; for consideration (row/column).

;;; We should make a better macro for this (ensuring valid subscripts
;;; in a list, or BETTER YET, a subscripting data structure
#|
  (defmacro subscripts-valid-p (subscripts)
     (check-type (elt subscripts 0) integer)
     (check-type (elt subscripts 1) integer))
|#
  
(defmethod xref ((df dataframe-listoflist) &rest subscripts)
  "Returns a scalar in array, in the same vein as aref, mref, vref,
etc. idx1/2 is row/col or case/var."
  (check-type (elt subscripts 0) integer)
  (check-type (elt subscripts 1) integer)
  (elt (elt (dataset df) (elt subscripts 0)) (elt subscripts 1)))

(defmethod (setf xref) (value (df dataframe-listoflist) &rest subscripts)
  "Sets a value for df-ml."
  (check-type (elt subscripts 0) integer)
  (check-type (elt subscripts 1) integer)

  ;; NEED TO CHECK TYPE!
  ;; (check-type val (elt (vartype df) index2))

  ;; below was originally 1 0 ?  have I mixed something up?
  (setf (elt (elt (dataset df) (elt subscripts 0)) (elt subscripts 1)) value))

;;;;;; IMPLEMENTATION INDEPENDENT FUNCTIONS AND METHODS
;;;;;; (use only xref, nrows, ncols and similar dataframe-like
;;;;;; components as core).

(defun xref-var (df index return-type)
  "Returns the data in a single variable as type.
type = sequence, vector, vector-like (if valid numeric type) or dataframe."
  (ecase return-type
    (('list)
     (map 'list
	  #'(lambda (x) (xref df index x))
	  (gen-seq (nth 2 (array-dimensions (dataset df))))))
    (('vector) t)
    (:vector-like t)
    (:matrix-like t)
    (:dataframe t)))

(defun xref-case (df index return-type)
  "Returns row as sequence."
  (ecase return-type
    (:list 
     (map 'list
	  #'(lambda (x) (xref df x index))
	  (gen-seq (nth 1 (array-dimensions (dataset df))))))
    (:vector t)
    (:vector-like t)
    (:matrix-like t)
    (:dataframe t)))

;; FIXME
(defun xref-2indexlist (df indexlist1 indexlist2 &key (return-type :array))
  "return an array, row X col dims.  FIXME TESTME"
  (case return-type
    (:array 
     (let ((my-pre-array (list)))
       (dolist (x indexlist1)
	 (dolist (y indexlist2)
	   (append my-pre-array (xref df x y))))
       (make-array (list (length indexlist1)
			 (length indexlist2))
		   :initial-contents my-pre-array)))
    (:dataframe
     (make-instance 'dataframe-array
		    :storage (make-array
			      (list (length indexlist1)
				    (length indexlist2))
			      :initial-contents (dataset df))
		    ;; ensure copy for this and following
		    :doc (doc-string df)
		    ;; the following 2 need to be subseted based on
		    ;; the values of indexlist1 and indexlist2
		    :case-labels (case-labels df)
		    :var-labels (var-labels df)))))

