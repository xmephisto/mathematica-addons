(* -*- mode: math; tab-width: 3; -*- *)

(*
	* $Log$
	* Revision 1.6  1998/05/19 04:09:32  aking
	* Default option is now Semisimple -> False, since this is more general.
	* Usage messages modified to make them clearer.
	* FieldNilSolve now does not use unify and listify.
	*
	* Revision 1.5  1998/05/18 23:25:51  aking
	* Errors flagged by NormalForm::shape now no longer return $Failed.
	*
	* Revision 1.4  1998/05/18 18:36:14  aking
	* Minor cosmetic modifications.
	*
	* Revision 1.3  1998/05/18 17:42:25  aking
	* Removed FunctionNormalForm, which appears to be trivial anyway.
	* Added error handling messages: NormalForm::shape, to all of the
	* Lie Series predicates.
	*
	* Revision 1.2  1998/05/14 17:23:35  aking
	* Minor cosmetic modifications.
	*
	* Revision 1.1  1998/04/27 04:33:45  aking
	* Initial revision
	*
*)

BeginPackage["NormalForm`", {"Frechet`", "Taylor`"}]

Unprotect[NormalForm, Semisimple, ForwardAdjointAction, BackwardAdjointAction,
	ForwardAction, BackwardAction, LieBracket, Jordan, VFTransform,
	Complexification, Realification, Expon, Generator, ResonanceTest]

NormalForm::usage = "{Y,U} = NormalForm[X,vars,order] reduces the vector\
	field X to its normal form using a Lie transform method.  It is assumed\
	that the linear part of the vector field X is in Jordan normal form.\
	Y is the normalized vector field and U the generator of the inverse of the\
	normalizing transformation.  Thus if u is the transformation generated by\
	U, (i.e., u = ForwardAction[vars,U,vars,order]), we have Du . X = Y o u,\
	and, if v = BackwardAction[vars,U,vars,order], then Dv . Y = X o v."

Options[NormalForm] = {Semisimple -> False, ResonanceTest -> Identity}

NormalForm::shape = "Incommensurate dimensions: Length[X] = `1` =!= `2` =\
	Length[vars]."

Semisimple::usage = "Semisimple is an option for NormalForm.  If the linear\
	part of the vector field to be reduced is diagonal, Semisimple -> True\
	is more efficient."

ResonanceTest::usage = "ResonanceTest is an option for NormalForm, which specifies\
	a function which is applied to divisors to determine whether they should be\
	treated as equal to zero.  The default is Identity."

ForwardAdjointAction::usage = "ForwardAdjointAction[X,U,vars,n] computes the\
	action of the generating vector field U upon the vector field X in variables\
	vars to order n.  Thus, if u is generated by U and\
	Y = ForwardAdjointAction[X,U,vars,n] then Du . Y = X o u."

BackwardAdjointAction::usage = "BackwardAdjointAction[X,U,vars,n] computes the\
	reverse action of the generating vector field U upon the vector field X in\
	variables vars to order n.  Thus, if u is generated by U and\
	Y = BackwardAdjointAction[X,U,vars,n] then Du . X = Y o u."

ForwardAction::usage = "ForwardAction[f,U,vars,n] computes the action of the\
	generating vector field U on the function f of variables vars to order n.\
	Thus, if u is generated by U and g = ForwardAction[f,U,vars,n], then\
	g = f o u.  In particular, to obtain u itself, note that u = Id o u, whence\
	u = ForwardAction[vars,U,vars,n]."

BackwardAction::usage = "BackwardAction[f,U,vars,n] computes the reverse action\
	of the generating vector field U on the function f of variables vars to order\
	n.  Thus, if u is generated by U and g = BackwardAction[f,U,vars,n], then\
	g o u = f.  In particular, to obtain the inverse of u, u^-1, note that\
	(u^-1) o u = Id, whence u^-1 = BackwardAction[vars,U,vars,n]."

LieBracket::usage = "LieBracket[X,Y,vars] is the Lie bracket of the vector\
	fields X and Y in the variables vars: [X,Y] = DX.Y - DY.X"

Jordan::usage = "{Y,f,g} = Jordan[X,oldvars,newvars] transforms the vector\
	field X so that its linear part is in Jordan normal form.  Y will be the\
	normalized vector field, f a linear change of variables such that\
	Df . Y = X o f, and g the inverse transformation, i.e., Dg . X = Y o g.\
	Put another way, (Df.Y) o g = X."
	
VFTransform::usage = "VFTransform[X,oldvars,f,newvars] transforms the vector\
	field X in oldvars by the coordinate transformation f by means of direct\
	substitution.  Thus, if Y = VFTransform[X,x,f,y], then Y = (D(f^-1).X) o f.\
	VFTransform[X,oldvars,f,newvars,n] gives the result to order n in newvars.\
	VFTransform[X,oldvars,f,newvars,t] should be used when the transformation\
	f depends on the independent variable t.  Likewise,\
	VFTransform[X,oldvars,f,newvars,t,n] gives the result of the time-dependent\
	transformation f on the vector field X to order n."

Complexification::usage = "Complexification[w,z] gives the complexifying\
	transformation {(w + z)/2, -I (w - z)/2}, where z is to be interpreted\
	as Conjugate[w]."

Realification::usage = "Realification[x,y] gives the realifying\
	transformation {x + I y, x - I y}."

Expon::usage = "Expon[X, vars, t, n], where X is a vector field in vars,\
	is Exp[t X] to order n."

Generator::usage = "Generator[f, vars, n], where f is a formal\
	diffeomorphism with linear part equal to the identity, is the vector\
	field in vars which generates f."

Begin["Private`"]

(* NormalForm[X,vars,order] reduces the vector field X to its normal form
	using a Lie transform method.  It is assumed that the linear part of the
	vector field X is in Jordan normal form.                                 *)

NormalForm[X_List, vars_List, order_Integer, opts___] := Block[
	{$RecursionLimit = Infinity},
	Module[{F,Xe,A,Y,eps,lambda,lieSolve,zeroTest},
		If[ Length[X] != Length[vars], 
			Message[NormalForm::shape, Length[X], Length[vars]];
		];
		lieSolve = If[Semisimple /. {opts} /. Options[NormalForm],
			FieldSSSolve,
			FieldNilSolve
		];
		zeroTest = ResonanceTest /. {opts} /. Options[NormalForm];
		Xe = Expand[X /. Thread[vars -> eps vars]];
		A = Coefficient[Xe, eps, 1];
		lambda = eigenvalues[A, vars];
		F[0, m_Integer] := F[0,m] = m! Coefficient[Xe, eps, m+1];
		F[i_Integer/;(i > 0), m_Integer] := F[i,m] = Expand[
			F[i-1,m+1] + Sum[
				Binomial[i-1,j] LieBracket[ Y[j], F[i-j-1,m], vars],
				{j,0,i-1}
			]
		];
		For[ i = 0, i < order-1, i++,
			{F[i+1,0], Y[i]} = lieSolve[
				A, lambda,
				Expand[
					F[i,1] + Sum[
						Binomial[i,j] LieBracket[Y[j], F[i-j,0], vars],
						{j,0,i-1}
					],
				],
				vars, i+1, zeroTest
			]
		];
		List[
			Expand[ Sum[ F[i,0] / i!, {i,0,order-1}] ],
			Expand[ Sum[ Y[i] / i!, {i,0,order-2}] ]
		]
	]
]

(* ForwardAdjointAction[X,Y,vars,order] calculates the action of the
	nilpotent vector field Y upon X.  That is, if 
			dy(x,e)/de = Y(y(x,e),e), and 
		Z = ForwardAdjointAction[X,Y,vars,order],
			then Z = ((Dy^(-1) X) o y).                               *)

ForwardAdjointAction[X_List, Y_List, vars_List, order_Integer] := 
	Module[{F,Xe,Ye,U,eps},
		If[Length[X] != Length[vars],
			Message[NormalForm::shape, Length[X], Length[vars]];
		];
		If[Length[Y] != Length[vars],
			Message[NormalForm::shape, Length[Y], Length[vars]];
		];
		Xe = Expand[X /. Thread[vars -> eps vars]];
		Ye = Expand[Y /. Thread[vars -> eps vars]];
		U[i_Integer] := U[i] = i! Coefficient[Ye, eps, i+2];
		F[i_Integer,0] := F[i,0] = i! Coefficient[Xe, eps, i+1];
		F[i_Integer, m_Integer/;(m > 0)] := F[i,m] = Expand[
			F[i+1,m-1] + Sum[ 
				Binomial[i,j] LieBracket[F[i-j,m-1], U[j], vars], 
				{j,0,i}
			]
		];
		Expand[ Sum[ F[0,m] / m!, {m,0,order-1}] ]
	]

(* BackwardAdjointAction[X,Y,vars,order] calculates the vector field
	Z such that the (forward) action of the nilpotent vector field Y 
	upon Z is X.                                                       *)

BackwardAdjointAction[X_List, Y_List, vars_List, order_Integer] := 
	Module[{F,Xe,Ye,U,eps},
		If[Length[X] != Length[vars],
			Message[NormalForm::shape, Length[X], Length[vars]];
		];
		If[Length[Y] != Length[vars],
			Message[NormalForm::shape, Length[Y], Length[vars]];
		];
		Xe = Expand[X /. Thread[vars -> eps vars]];
		Ye = Expand[Y /. Thread[vars -> eps vars]];
		U[i_Integer] := U[i] = i! Coefficient[Ye, eps, i+2];
		F[0, m_Integer] := F[0,m] = m! Coefficient[Xe, eps, m+1];
		F[i_Integer/;(i > 0), m_Integer] := F[i,m] = Expand[
			F[i-1,m+1] - Sum[ 
				Binomial[i-1,j] LieBracket[F[i-j-1,m], U[j], vars], 
				{j,0,i-1}
			]
		];
		Expand[ Sum[ F[i,0] / i!, {i,0,order-1}] ]
	]

(* ForwardAction[F,Y,vars,order] calculates the action of the
	nilpotent vector field Y upon the function F.  If 
			dy(x,e)/de = Y(y(x,e),e), and 
			G = ForwardAction[F,Y,x,order], then
				G(x,e) = F(y(x,e),e).                            *)

ForwardAction[X_List, Y_List, vars_List, order_Integer] :=
	 Module[{F,Xe,Ye,U,eps},
		If[Length[X] != Length[vars],
			Message[NormalForm::shape, Length[X], Length[vars]];
		];
		If[Length[Y] != Length[vars],
			Message[NormalForm::shape, Length[Y], Length[vars]];
		];
		Xe = Expand[X /. Thread[vars -> eps vars]];
		Ye = Expand[Y /. Thread[vars -> eps vars]];
		U[i_Integer] := U[i] = i! Coefficient[Ye, eps, i+2];
		F[i_Integer,0] := F[i,0] = i! Coefficient[Xe, eps, i+1];
		F[i_Integer, m_Integer/;(m > 0)] := F[i,m] = Expand[
			F[i+1,m-1] + Sum[ 
				Binomial[i,j] (Frechet[F[i-j,m-1],vars] . U[j]),
				{j,0,i}
			]
		];
		Expand[ Sum[ F[0,m] / m!, {m,0,order-1}] ]
	]

(* BackwardAction[F,Y,vars,order] calculates the function G
	such that the action of the nilpotent vector field Y upon 
	G results in the function F.  If 
					dy(x,e)/de = Y(y(x,e),e), and 
		G = BackwardAction[F,Y,x,order], then
					F(x,e) = G(y(x,e),e).                          *)

BackwardAction[X_List, Y_List, vars_List, order_Integer] :=
	 Module[{F,Xe,Ye,U,eps},
		If[Length[X] != Length[vars],
			Message[NormalForm::shape, Length[X], Length[vars]];
		];
		If[Length[Y] != Length[vars],
			Message[NormalForm::shape, Length[Y], Length[vars]];
		];
		Xe = Expand[X /. Thread[vars -> eps vars]];
		Ye = Expand[Y /. Thread[vars -> eps vars]];
		U[i_Integer] := U[i] = i! Coefficient[Ye, eps, i+2];
		F[0, m_Integer] := F[0,m] = m! Coefficient[Xe, eps, m+1];
		F[i_Integer/;(i > 0), m_Integer] := F[i,m] = Expand[
			F[i-1,m+1] - Sum[ 
				Binomial[i-1,j] (Frechet[F[i-j-1,m],vars] . U[j]),
				{j,0,i-1}
			]
		];
		Expand[ Sum[ F[i,0] / i!, {i,0,order-1}] ]
	]

(* Generator[F,vars,order] calculates the nilpotent vector field X
	such that the action of X upon the identity gives the function F.  *)

Generator[f_List, vars_List, n_Integer] := Module[
	{Y, eps, fe},
	If[ Length[f] != Length[vars], 
		Message[NormalForm::shape, Length[f], Length[vars]];
	];
	fe = f /. Thread[vars -> eps vars];
	Y[0, k_Integer] := Y[0,k] = (k+1)! Coefficient[fe, eps, k+2];
	Y[i_Integer/;(i > 0), k_Integer] := Y[i,k] = 
		Y[i-1,k+1] - Sum[
			Binomial[i-1, j] Frechet[Y[j,k], vars] . Y[i-j-1,0],
			{j,0,i-1}
		];
	Expand[Sum[ Y[i,0] / i!, {i,0,n-2}]]
]

LieBracket[X_List, Y_List, vars_List] := 
	Frechet[X,vars].Y - Frechet[Y,vars].X

(* Jordan[X,old,new] puts the linear part of the vector field X into 
	Jordan normal form, returning the normalized vector field and the
	direct and inverse linear normalizing transformations.  Thus, if
		{Y,f,g} = Jordan[X,old,new], then
			Y = (Dg . X) o f  and X = (Df . Y) o g.                    *)

Jordan[X_List, oldvars_List, newvars_List] := Module[
	{A = Frechet[Taylor[X,oldvars,1], oldvars],
		S, T, f, g, Y},
	If[Length[X] != Length[oldvars],
		Message[NormalForm::shape, Length[X], Length[oldvars]];
	];
	If[Length[X] != Length[newvars],
		Message[NormalForm::shape, Length[X], Length[newvars]];
	];
	S = First[JordanDecomposition[A]];
	T = Inverse[S];
	f = S . newvars;
	g = T . oldvars;
	Y = Expand[T . (X /. Thread[oldvars -> f])];
	{Y, f, g}
]

(* If Y = VFTransform[X,old,f,new] then Y = ((Df^-1).X) /. Thread[old -> f].
	If Y = VFTransform[X,old,f,new.n] then Y = ((Df^-1).X) /. Thread[old -> f]. 
	truncated to order n in the new variables.  										*)


VFTransform[X_List, old_List, sub_List, new_List] := Expand[
	Inverse[Frechet[sub,new]] . (X /. Thread[old -> sub])
]

VFTransform[X_List, old_List, sub_List, new_List, order_Integer] := Module[
	{dsdx, ff, eps},
	ff = Taylor[X /. Thread[old -> sub], new, order];
	dsdx = Taylor[Inverse[Frechet[sub,new]], new, order];
	Taylor[ dsdx . ff, new, order]
]

VFTransform[X_List, old_List, sub_List, new_List, t_Symbol] := Expand[
	Inverse[Frechet[sub,new]] . ((X /. Thread[old -> sub]) - D[sub,t])
]

VFTransform[X_List, old_List, sub_List, new_List, t_Symbol, order_Integer] := 
	Module[{dsdx, ff, eps},
		ff = Taylor[X /. Thread[old -> sub], new, order];
		dsdx = Taylor[Inverse[Frechet[sub,new]], new, order];
		Taylor[
			dsdx . ((X /. Thread[old -> sub]) - D[sub,t]),
			new, order
		]
	]

(* Solve [X,Y] + G = F in the space of homogeneous polynomial vector
	fields, where X is a vector field of degree zero (i.e. linear) and
	in diagonal form. *)

FieldSSSolve[_, eigs_List, X_List, vars_List, _, zero_] := Transpose[
	Table[
		FieldSSSolveAux[eigs, Expand[X[[i]]], vars, eigs[[i]], zero],
		{i, 1, Length[vars]}
	]
]

FieldSSSolveAux[_, 0_, _, _, _] := {0, 0}

FieldSSSolveAux[eigs_List, a_ + b_, vars_, lambda_, zero_] := 
	FieldSSSolveAux[eigs,a,vars,lambda,zero] + 
	FieldSSSolveAux[eigs,b,vars,lambda,zero]

FieldSSSolveAux[eigs_List, a_, vars_, lambda_, zero_] := 
	Module[{divisor = lambda - eigs . Exponent[a,vars]},
		If[ zero[divisor] == 0,
			{a,0},
			{0,a/divisor},
			{0,a/divisor}
		]
	]

(* Solve [X,Y] + G = F in the space of homogeneous polynomial vector
	fields, where X is a vector field of degree zero (i.e. linear) and
	in not-necessarily-diagonal Jordan normal form. *)

FieldNilSolve[X_List, L_List, F_List, vars_List, deg_Integer, zero_] :=
	Module[
		{DX = Transpose[Frechet[X,vars]], M = Monomials[deg+1,vars], 
			G = F, n = Length[vars], Y, m, i, k},
		m = Length[M];
		For[k = n, k >= 1, k--,
			For[i = 1, i <= m, i++,
				Y[i,k] = FieldNilSolveAux[
					Coefficient[G[[k]], M[[i]]] M[[i]], 
					vars, L, k, zero
				];
				G -= DX[[k]] Y[i,k];
				G[[k]] += Frechet[Y[i,k],vars] . X;
			]
		];
		{G, Table[Sum[Y[i,k], {i,1,m}], {k,1,n}]}
	]

FieldNilSolveAux[0, _List, _List, _Integer, _] := 0

FieldNilSolveAux[f_/;(f =!= 0), vars_List, eigs_List, k_Integer, zero_] := 
	Module[{divisor = eigs[[k]] - eigs . Exponent[f,vars]},
		If[ zero[divisor] == 0,
			0,
			f/divisor,
			f/divisor
		]
	]

Monomials[0, {x___}] := {1}

Monomials[order_Integer/;(order > 0), {}] := {}

Monomials[order_Integer/;(order > 0), {x_, y___}] := Flatten[
	Table[
		(x^(order-k) #)& /@ Monomials[k, {y}],
		{k,0,order}
	]
]

eigenvalues[{},{}] = {}

eigenvalues[{0, f___}, {_, r___}] := 
	Prepend[eigenvalues[{f}, {r}], 0]

eigenvalues[{(c_:1) x_, f___}, {x_, r___}] := 
	Prepend[eigenvalues[{f}, {r}], c]

eigenvalues[{(c_:1) x_ + ___, f___}, {x_, r___}] := 
	Prepend[eigenvalues[{f}, {r}], c]

eigenvalues[{_, f___}, {x_, r___}] := 
	Prepend[eigenvalues[{f},{r}], 0]

Grade[X_, vars_List] := Module[
	{eps,Y},
	Y = X /. Thread[vars -> eps vars];
	Table[
		Coefficient[Y,eps,k],
		{k,0,Max[Exponent[Y,eps]]}
	]
]

Grade[X_, vars_List, grade_List] := Module[
	{eps,Y},
	Y = X /. Thread[vars -> (eps^grade) vars];
	Table[
		Coefficient[Y,eps,k],
		{k,0,Max[Exponent[Y,eps]]}
	]
]

Complexification[w_, z_] := {w/2 + z/2, -I w/2 + I z/2}

Realification[x_, y_] := {x + I y, x - I y}

Expon[X_List, vars_List, t_Symbol, n_Integer] := 
	Expon[t X, vars, n]

Expon[X_List, vars_List, n_Integer] := Module[
	{Y = (X . Frechet[#,vars])&},
	(NestList[Y,#,n]& /@ vars) . Table[(1 / k!), {k,0,n}]
]

End[ ]

Protect[NormalForm, Semisimple, ForwardAdjointAction,
	BackwardAdjointAction, ForwardAction, BackwardAction, LieBracket,
	Jordan, VFTransform, Complexification, Realification, Expon,
	Generator, ResonanceTest]

EndPackage[ ]
