-- X ::= A B C
v_X = {
  A = 'v(A)',
  B = 'v(B)',
  C = 'v(C)',
}

print ( v_X.A, v_X.B, v_X.C )

-- X ::= A B A
v_X = {
  A = { [1] = 'v(A:1)', [2] = 'v(A:2)' },
  B = 'v(B)'
}

vXA1 = v_X.A[1]; vXA2 = v_X.A[2]; vXB = v_X.B

print ( v_X.A[1], v_X.A[2], v_X.B )
