:- use_module(library(obo_metadata/oio)).
:- use_module(library(obo_metadata/iao_metadata)).
%:- use_module(library(rdf_owl/owl)).

:- use_module(library(sparqlprog/emulate_builtins)).

:- rdf_register_prefix('MONDO','http://purl.obolibrary.org/obo/MONDO_').
:- rdf_register_prefix('HP','http://purl.obolibrary.org/obo/HP_').
:- rdf_register_prefix('NCIT','http://purl.obolibrary.org/obo/NCIT_').
:- rdf_register_prefix('DOID','http://purl.obolibrary.org/obo/DOID_').
:- rdf_register_prefix('MESH','http://purl.obolibrary.org/obo/MESH_').
:- rdf_register_prefix('GARD','http://purl.obolibrary.org/obo/GARD_').
:- rdf_register_prefix('SCTID','http://purl.obolibrary.org/obo/SCTID_').
:- rdf_register_prefix('UMLS','http://linkedlifedata.com/resource/umls/id/').
:- rdf_register_prefix('MEDGEN','http://purl.obolibrary.org/obo/MEDGEN_').
:- rdf_register_prefix('EFO','http://www.ebi.ac.uk/efo/EFO_').
:- rdf_register_prefix('ICD10','http://purl.obolibrary.org/obo/ICD10_').
:- rdf_register_prefix('Orphanet','http://www.orpha.net/ORDO/Orphanet_').
:- rdf_register_ns(oio,'http://www.geneontology.org/formats/oboInOwl#').

% fake
:- rdf_register_prefix('DC','http://purl.obolibrary.org/obo/DC_').
:- rdf_register_prefix('COHD','http://purl.obolibrary.org/obo/COHD_').
:- rdf_register_prefix('OMIMPS','http://purl.obolibrary.org/obo/OMIMPS_').

foo('0').


% TODO: add to owl vocab
dep(C) :- rdf(C,owl:deprecated,_).

solutions(X,G,L) :-
        setof(X,X^G,L),
        !.
solutions(_,_,[]).

xref_prefix(C,X,P) :-
        has_dbxref(C,X),
        curie_prefix(X,P).

xref_src(C,X,S) :-
        xref_src(C,X,_,S).
xref_src(C,X,A,S) :-
        has_dbxref_axiom(C,X,A),
        rdf(A,oio:source,S).

xref_prefix_srcont(C,X,P,S) :-
        xref_prefix(C,X,P),
        xref_src(C,X,SC),
        curie_prefix(SC,S).



curie_prefix(Literal,Pre) :-
        str_before(Literal,":",Pre).

mondo_equiv_xref(C,X) :-
        xref_src(C,X,_,"MONDO:equivalentTo").
mondo_equiv_xref(C,X,P) :-
        xref_src(C,X,_,"MONDO:equivalentTo"),
        curie_prefix(X,P).


mondo_xref_semantics(C,X,Rel,P) :-
        xref_src(C,X,_,Src),
        curie_prefix(X,P),
        src_semantics(Src,Rel).
mondo_xref_semantics(C,X,Rel) :-
        xref_src(C,X,_,Src),
        src_semantics(Src,Rel).


src_semantics("MONDO:equivalentTo",(=)) :- !.
src_semantics("MONDO:subClassOf",(<)) :- !.
src_semantics("MONDO:superClassOf",(>)) :- !.
src_semantics("MONDO:relatedTo",(~)) :- !.
src_semantics(_,(-)) :- !.




mondo_equiv_class_via_xref(C,XC,P) :-
        mondo_equiv_xref(C,X,P),
        curie_uri(X,XC).
mondo_equiv_class_via_xref(C,XC) :-
        mondo_equiv_xref(C,X),
        curie_uri(X,XC).


rare_disease('MONDO:0021200').

rare(C) :- rare_disease(C).
rare(C) :- mondo_equiv_xref(C,_,'OMIM').

%! curie_uri(+Literal:literal, ?URI:atom) is semidet
curie_uri(Literal,URI) :-
        Literal = S^^_,
        atom_string(A,S),
        concat_atom([Pre,Post],':',A),
        \+ \+ rdf_current_prefix(Pre,_),
        rdf_global_id(Pre:Post,URI).

% TODO
uri_curie(URI,Literal) :-
        rdf_global_id(Pre:Post,URI),
        concat_atom([Pre,Post],':',A),
        atom_string(A,Literal).

uri_prefix(URI,Prefix) :-
        rdf_global_id(Prefix:_,URI).

ont_missing_xref(Ont,X) :-
        class(X),
        uri_prefix(X,Ont),
        uri_curie(X,XId),
        \+ has_dbxref(_,XId).

ordo_missing_xref(C,Xs) :-
        class(C),
        rdfs_subclass_of(C,'http://purl.obolibrary.org/obo/Orphanet_C001'),
        uri_curie(C,CId),
        \+ has_dbxref(_,CId),
        solutions(X,has_dbxref(C,X),Xs).

ordo_missing_xref_src(C,X,S) :-
        class(C),
        rdfs_subclass_of(C,'http://purl.obolibrary.org/obo/Orphanet_C001'),
        uri_curie(C,CId),
        \+ has_dbxref(_,CId),
        xref_src(C,X,S).

ext_merged(X1,X2,C) :-
        ext_merged(X1,X2,C,_).
ext_merged(XC1,XC2,C,P) :-
        mondo_equiv_xref(C,X1),
        mondo_equiv_xref(C,X2),
        curie_prefix(X1,P),
        curie_prefix(X2,P),
        curie_uri(X1,XC1),
        curie_uri(X2,XC2),
        X1 @< X2.

equivalent_to_deprecated(C,X) :-
        owl_equivalent_class(C,X),
        C\=X,
        deprecated(X).

equivalent_to_replaced_by(C,X,Y) :-
        owl_equivalent_class(C,X),
        C\=X,
        deprecated(X),
        term_replaced_by(X,Y).

simj_merge_candidates(C1,C2,S,N1,N2) :-
        simj_by_subclass(C1,C2,S,N1,N2),
        N1 > 3,
        S > 0.8,
        C1 @< C2.


