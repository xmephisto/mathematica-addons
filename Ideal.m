(* -*- mode: math; tab-width: 3; -*- *)

BeginPackage["Ideal`", {"Taylor`"}]

Unprotect[MultiIndices, Monomials, IdealSum, IdealProduct, IdealQuotient, 
	IdealIntersection, Saturation, Homogeneize, Dehomogeneize, GeneralPolynomial, 
	StandardBasis, SeriesReduce, TangentCone, BlockDiagonal, 
	GrevLex, GrLex, Elim, Lex]

MultiIndices::usage = "MultiIndices[k, n] gives the list of\
	 n-dimensional multi-indices of order k."

Monomials::usage = "Monomials[k, vars] gives the list of all homogenous\
	monomials in variables vars of degree k."

IdealSum::usage = "IdealSum[F, G, vars] computes a Groebner basis\
	for the ideal <F> + <G> in the ring k[vars]."

IdealProduct::usage = "IdealProduct[F, G, vars] computes a Groebner\
	 basis for the ideal <F><G> in the ring k[vars]."

IdealQuotient::usage = "IdealQuotient[F, G, vars] computes a Groebner\
	basis for the ideal <F>:<G> in the ring k[vars]."

IdealIntersection::usage = "IdealIntersection[F, G, vars] computes\
	a Groebner basis for the intersection of <F> and <G> in the ring\
	k[vars]."

Saturation::usage = "Saturation[F, G, vars] computes the saturation\
	of the ideal with basis F with respect to the ideal generated by\
	G.  F must be a list of polynomials in the variables vars; G may\
	be a single polynomial in vars or a list of such polynomials;\
	vars must be a list."

Homogeneize::usage = "Homogeneize[F, vars, z] homogeneizes the polynomial\
	or polynomials F in variables vars, using z as the variable of\
	homogeneization."

Dehomogeneize::usage = "Dehomogeneize[F, z] dehomogeneizes the polynomial\
	or polynomials F by setting z to 1."

GeneralPolynomial::usage = "GeneralPolynomial[A, vars, degs] gives\
	the general polynomial in vars to degree degs.  The coefficients\
	are functions of A."

Options[GeneralPolynomial] = {Homogeneous -> False}

StandardBasis::usage = "StandardBasis[F, vars] computes the standard basis\
	of the ideal generated by F inr k[vars]."

SeriesReduce::usage = "SeriesReduce[f, {g1, g2, ... }, {x1, x2, ... }] yields\
	a list representing a reduction of f modulo the standard basis G.  The\
	list has the form {{a1, a2, ... }, b}, where b is minimal and\
	a1 g1 + a2 g2 + ...  + b is exactly f."

TangentCone::usage = "TangentCone[F, vars] computes the tangent cone of the\
	ideal with basis F in k[vars]."

BlockDiagonal::usage = "BlockDiagonal[a,b,...] gives the block diagonal matrix\
	upon whose diagonal are the matrices a, b, ...."

GrevLex::usage = "GrevLex[n] gives an n x n weight matrix for the graded reverse\
	lexicographical order."

GrLex::usage = "GrLex[n] gives an n x n weight matrix for the graded\
	lexicographical order."

Elim::usage = "Elim[k,n] gives an n x n weight matrix for the k-th elimination\
	order."

Lex::usage = "Lex[n] gives an n x n weight matrix for the lexicographical order."

Begin["Private`"]

MultiIndices[order_Integer, 1] := {{order}}

MultiIndices[0, n_Integer] := {Array[0&, n]}

MultiIndices[order_Integer/;(order > 0), n_Integer/;(n > 1)] := Join @@
	Table[
		Append[#,i]& /@ MultiIndices[order-i, n-1],
		{i,0,order}
	]

Monomials[order_Integer, vars_List] :=
	Apply[Times,vars^#]& /@ MultiIndices[order,Length[vars]]

IdealSum[F_List, G_List, X_List, opts___] := 
	GroebnerBasis[Join[F,G], X, opts]

IdealProduct[F_List, G_List, X_List, opts___] :=
	GroebnerBasis[Flatten[Outer[Times,F,G]], X, opts]

IdealIntersection[F_List, G_List, X_List, opts___] := Module[
	{t, H},
	H = GroebnerBasis[
		Join[t F, (1 - t) G],
		Prepend[X,t],
		addLex[Length[X],opts]
	];
	Select[H, (!MemberQ[Variables[#],t])&]
]

IdealQuotient[F_List, G_List, X_List, opts___] := Module[
	{K, L},
	K = IdealIntersection[F, {#}, X, opts]& /@ G;
	L = Table[
		Flatten[PolynomialReduce[#,{G[[k]]},X,opts][[1]]& /@ K[[k]]],
		{k,1,Length[K]}
	];
	Fold[IdealIntersection[#1, #2, X, opts]&, L[[1]], Rest[L]]
]

Saturation[F_List, G_List, X_List, opts___] := 
	Fold[Saturation[#1, #2, X, opts]&, F, G]

Saturation[F_List, G_, X_List, opts___] := Module[
	{t, H},
	H = GroebnerBasis[
		Append[F, 1 - t G],
		Prepend[X,t],
		addLex[Length[X],opts]
	];
	Select[H, (!MemberQ[Variables[#],t])&]
]
	
Homogeneize[p_List, x_List, z_] := Homogeneize[#,x,z]& /@ p

Homogeneize[p_, x_List, z_] := Expand[z^TotalDegree[p,x] (p /. Thread[x -> x / z])]

Homogeneize[p_, x_, z_] := Homogeneize[p,{x},z]

Dehomogeneize[p_, z_] := (p /. z -> 1)

SplitIdeal[f_List, g_] := Module[
	{satideal = Saturation[f,g], addideal, 
		allvars = Union[Variables[f], Variables[g]]},
	If [Length[f] == Length[ f ~Union~ satideal ],
		Return[ {f} ],
	(	addideal = GroebnerBasis[Append[f, g], allvars];
		Return[{satideal, addideal}])
	]
]

GeneralPolynomial[A_, {x_, y__}, n_Integer] := 
	Expand[Sum[GeneralPolynomialAux[A, {y}, n-k, {k}] x^k, {k,0,n}]]

GeneralPolynomial[A_, x_, n_Integer] := Sum[A[k] x^k, {k,0,n}]

GeneralPolynomial[A_, {x_}, {n_Integer}] := Expand[Sum[A[k] x^k, {k,0,n}]]

GeneralPolynomial[A_, {x_, y__}, {n_Integer, m__Integer}] := 
	Expand[Sum[GeneralPolynomialAux[A, {y}, {m}, {k}] x^k, {k,0,n}]]

GeneralPolynomialAux[A_, {x_, y__}, n_Integer, {K__}] := 
	Sum[GeneralPolynomialAux[A, {y}, n-k, {K,k}] x^k, {k,0,n}]

GeneralPolynomialAux[A_, {x_}, n_Integer, {K__}] := Sum[A[K,k] x^k, {k,0,n}]

GeneralPolynomialAux[A_, {x_}, {n_Integer}, {K__}] := Sum[A[K,k] x^k, {k,0,n}]

GeneralPolynomialAux[A_, {x_, y__}, {n_Integer, m__Integer}, {K__}] := 
	Sum[GeneralPolynomialAux[A,{y},{m},{K,k}] x^k, {k,0,n}]

StandardBasis[F_List, X_List, opts___] := Module[
	{z, G},
	G = GroebnerBasis[
		Homogeneize[F,X,z],
		Prepend[X,z],
		addLex[Length[X],opts]
	];
	Dehomogeneize[G,z]
]

SeriesReduce[f_List, F_List, X_List, opts___] := 
	SeriesReduce[#, F, X, opts]& /@ f

SeriesReduce[f_, F_List, X_List, opts___] := Module[
	{z, H},
	H = PolynomialReduce[
		Homogeneize[f,X,z],
		Homogeneize[F,X,z];
		Prepend[X,z],
		addLex[Length[X],opts]
	];
	Dehomogeneize[H,z]
]	

TangentCone[F_List, X_List, opts___] := GroebnerBasis[
	InitialForm[StandardBasis[F,X,opts],X], X, opts
]

TangentCone[f_, X_List, opts___] := TangentCone[{f},X,opts]

BlockDiagonal[a_] := a

BlockDiagonal[a_, b__] := blockDiagonalAux[a, b]

blockDiagonalAux[a_] := a

blockDiagonalAux[a_, b_, c___] := Module[
	{da = Dimensions[a], db = Dimensions[b], A},
	A = Array[0&, da+db];
	A[[Range[1,da[[1]]],Range[1,da[[2]]]]] = a;
	A[[da[[1]] + Range[1,db[[1]]], da[[2]] + Range[1,db[[2]]]]] = b;
	Return[ blockDiagonalAux[A,c] ]
]

GrevLex[n_Integer] := Array[
	If[#1 == 1, 1, If[ #1 + #2 == n + 2, -1, 0]]&,
	{n, n}
]

GrLex[n_Integer] := Array[
	If[#1 == 1, 1, If[ #1 - #2 == 1, 1, 0]]&,
	{n, n}
]

Elim[k_Integer, n_Integer] := Part[
	BlockDiagonal[GrevLex[k], GrevLex[n-k]],
	Join[{1},Range[k+1,n],Range[2,k]]
]

(* Elim[k_Integer, n_Integer] := Join[
	{
		Join[Array[1&,k], Array[0&, n-k]],
		Join[Array[0&,k], Array[1&, n-k]]
	},
	Array[If[#1 + #2 == n + 1, -1, 0]&, {n-2,n}]
] *)

Lex[n_Integer] := IdentityMatrix[n]

addLex[n_Integer, opts___] := Module[
	{weight = MonomialOrder /. {opts} /. Options[GroebnerBasis]},
	Which[
		weight === DegreeReverseLexicographic,
			weight = BlockDiagonal[Lex[1],GrevLex[n]],
		MatrixQ[weight],
			If[ 
				!(( Equal @@ Dimensions[weight]) && (Length[weight] == n)),
				Message[GroebnerBasis::mnmord1]; Return[opts]
			];
			weight = BlockDiagonal[Lex[1],weight]
	];
	Sequence @@ ({opts} /. (Rule[MonomialOrder, z_] :> Rule[MonomialOrder,weight]))
]

End[ ]

Protect[MultiIndices, Monomials, IdealSum, IdealProduct, IdealQuotient, 
	IdealIntersection, Saturation, Homogeneize, Dehomogeneize, GeneralPolynomial, 
	StandardBasis, SeriesReduce, TangentCone, BlockDiagonal, 
	GrevLex, GrLex, Elim, Lex]

EndPackage[ ]
