# This file is a part of BAT.jl, licensed under the MIT License (MIT).


_iscontiguous(A::Array) = true
_iscontiguous(A::AbstractArray) = Base.iscontiguous(A)


_car_cdr_impl() = ()
_car_cdr_impl(x, y...) = (x, (y...,))
_car_cdr(tp::Tuple) = _car_cdr_impl(tp...)

function _all_lteq(A::AbstractArray, B::AbstractArray, C::AbstractArray)
    axes(A) == axes(B) == axes(C) || throw(DimensionMismatch("A, B and C must have the same indices"))
    result = 0
    @inbounds @simd for i in eachindex(A, B, C)
        result += ifelse(A[i] <= B[i] <= C[i], 1, 0)
    end
    result == length(eachindex(A))
end


@inline function _all_lteq_impl(a::Real, B::AbstractArray, c::Real)
    result = 0
    @inbounds @simd for b in B
        result += ifelse(a <= b <= c, 1, 0)
    end
    result == length(eachindex(B))
end

_all_lteq(a::Real, B::AbstractArray, c::Real) = _all_lteq_impl(a, B, c)




doc"""
    @propagate_inbounds sum_first_dim(A::AbstractArray, j::Integer, ks::Integer...)

Calculate the equivalent of `sum(A[:, j, ks...])`.
"""
Base.@propagate_inbounds function sum_first_dim(A::AbstractArray, j::Integer, ks::Integer...)
    s = zero(eltype(A))
    @boundscheck if !Base.checkbounds_indices(Bool, Base.tail(indices(A)), (j, ks...))
        throw(BoundsError(A, (:, j)))
    end
    @inbounds for i in indices(A, 1)
        s += A[i, j, ks...]
    end
    s
end


doc"""
    @propagate_inbounds sum_first_dim(A::AbstractArray)

If `A` is a vector, return `sum(A)`, else `sum(A, 1)[:]`.
"""
sum_first_dim(A::AbstractArray) = sum(A, 1)[:]
sum_first_dim(A::AbstractVector) = sum(A)


const SingleArrayIndex = Union{Integer, CartesianIndex}


Base.@propagate_inbounds function _swap!(A::AbstractArray, i_A::SingleArrayIndex, B::AbstractArray, i_B::SingleArrayIndex)
    tmp = A[i_A]
    A[i_A] = B[i_B]
    B[i_B] = tmp
    A
end


function _swap!(A::AbstractArray, B::AbstractArray)
    size(A) == size(B) || throw(DimensionMismatch("Can only swap arrays with equal size"))
    @inbounds @simd for i in eachindex(A, B)
        _swap!(A, i, B, i)
    end
    A
end
