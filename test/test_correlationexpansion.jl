using Base.Test
using QuantumOptics

srand(0)

b1 = FockBasis(2)
b2 = SpinBasis(1//2)
b3 = NLevelBasis(4)
b4 = NLevelBasis(2)
b = tensor(b1, b2, b3, b4)

function test_op_equal(op1, op2, eps=1e-10)
    @test_approx_eq_eps 0. tracedistance_general(full(op1), full(op2)) eps
end

# Test Masks
mask = correlationexpansion.indices2mask(3, [1,2])
@test mask == (true, true, false)
indices = correlationexpansion.mask2indices(mask)
@test indices == [1,2]

S1 = correlationexpansion.correlationmasks(4, 1)
S2 = correlationexpansion.correlationmasks(4, 2)
S3 = correlationexpansion.correlationmasks(4, 3)
S4 = correlationexpansion.correlationmasks(4, 4)
@test S1 == Set([(true, false, false, false), (false, true, false, false), (false, false, true, false), (false, false, false, true)])
@test S2 == Set([(true, true, false, false), (true, false, true, false), (true, false, false, true),
                 (false, true, true, false), (false, true, false, true), (false, false, true, true)])
@test S3 == Set([(false, true, true, true), (true, false, true, true), (true, true, false, true), (true, true, true, false)])
@test S4 == Set([(true, true, true, true)])

# Test creation of ApproximateOperator
op1 = DenseOperator(b, rand(Complex128, length(b), length(b)))
op1_ = correlationexpansion.approximate(op1, S2 ∪ S3 ∪ S4)
test_op_equal(op1, op1_)

# Test multiplication
h1 = DenseOperator(b1, rand(Complex128, length(b1), length(b1)))
h2 = DenseOperator(b2, rand(Complex128, length(b2), length(b2)))
h3 = DenseOperator(b3, rand(Complex128, length(b3), length(b3)))
h4 = DenseOperator(b4, rand(Complex128, length(b4), length(b4)))
h = 0.5*lazy(h1) ⊗ lazy(h2) ⊗ lazy(h3) ⊗ lazy(h4)

test_op_equal(full(h)*0.3*full(op1_), h*(0.3*op1_))
test_op_equal(full(op1_)*0.3*full(h), (op1_*0.3)*h)

# Test ptrace
test_op_equal(ptrace(full(h)*op1, 1), ptrace(h*op1_, 1))
test_op_equal(ptrace(full(h)*op1, 2), ptrace(h*op1_, 2))
test_op_equal(ptrace(full(h)*op1, 3), ptrace(h*op1_, 3))
test_op_equal(ptrace(full(h)*op1, 4), ptrace(h*op1_, 4))
test_op_equal(ptrace(full(h)*op1, [1,2]), ptrace(h*op1_, [1,2]))
test_op_equal(ptrace(full(h)*op1, [1,3]), ptrace(h*op1_, [1,3]))
test_op_equal(ptrace(full(h)*op1, [1,4]), ptrace(h*op1_, [1,4]))
test_op_equal(ptrace(full(h)*op1, [2,3]), ptrace(h*op1_, [2,3]))
test_op_equal(ptrace(full(h)*op1, [2,4]), ptrace(h*op1_, [2,4]))
test_op_equal(ptrace(full(h)*op1, [3,4]), ptrace(h*op1_, [3,4]))
test_op_equal(ptrace(full(h)*op1, [1,2,3]), ptrace(h*op1_, [1,2,3]))
test_op_equal(ptrace(full(h)*op1, [1,2,4]), ptrace(h*op1_, [1,2,4]))
test_op_equal(ptrace(full(h)*op1, [1,3,4]), ptrace(h*op1_, [1,3,4]))
test_op_equal(ptrace(full(h)*op1, [2,3,4]), ptrace(h*op1_, [2,3,4]))

# Test dmaster
# b1 = FockBasis(2)
# b2 = SpinBasis(1//2)
# b = tensor(b1, b2)
# S2 = correlationexpansion.correlationmasks(2, 2)

psi1 = normalize(Ket(b1, rand(Complex128, length(b1))))
psi2 = normalize(Ket(b2, rand(Complex128, length(b2))))
psi3 = normalize(Ket(b3, rand(Complex128, length(b3))))
psi4 = normalize(Ket(b4, rand(Complex128, length(b4))))

rho1 = psi1 ⊗ dagger(psi1)
rho2 = psi2 ⊗ dagger(psi2)
rho3 = psi3 ⊗ dagger(psi3)
rho4 = psi4 ⊗ dagger(psi4)

rho = rho1 ⊗ rho2 ⊗ rho3 ⊗ rho4
rho_ = correlationexpansion.approximate(rho, S2 ∪ S3 ∪ S4)

H = LazySum(h, dagger(h))
T = [0.:0.01:0.1;]
tout_, rho_t_ = correlationexpansion.master(T, rho_, H, LazyTensor[])
tout, rho_t = timeevolution.master(T, full(rho_), full(H), [])
# @time tout_, rho_t_ = correlationexpansion.master(T, rho_, H, LazyTensor[])
# @time tout_, rho_t_ = correlationexpansion.master(T, rho_, H, LazyTensor[])
# @time tout, rho_t = timeevolution.master(T, full(rho_), full(H), [])
# @time tout, rho_t = timeevolution.master(T, full(rho_), full(H), [])
for i=1:length(rho_t)
    test_op_equal(rho_t[i], rho_t_[i], 1e-5)
end