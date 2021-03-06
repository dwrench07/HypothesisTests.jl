# kruskal_wallis.jl
# Kruskal-Wallis rank sum test
#
# Copyright (C) 2014   Christoph Sawade
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

export KruskalWallisTest

immutable KruskalWallisTest <: HypothesisTest
    n_i::Vector{Int}         # number of observations in each group
    df::Int                  # degrees of freedom
    R_i::Vector{Float64}     # rank sums
    H::Float64               # test statistic: chi-square statistic
    tie_adjustment::Float64  # adjustment for ties
end

function KruskalWallisTest{T<:Real}(groups::AbstractVector{T}...)
    (H, R_i, tieadj, n_i) = kwstats(groups...)
    if length(groups)<=3 && any(n_i .< 6)
        warn("This test is only asymptotically correct and might be inaccurate for the given group size")
    end
    df = length(groups) - 1
    KruskalWallisTest(n_i, df, R_i, H, tieadj)
end

testname(::KruskalWallisTest) = "Kruskal-Wallis rank sum test (chi-square approximation)"
population_param_of_interest(x::KruskalWallisTest) = ("Location parameters", "all equal", NaN) # parameter of interest: name, value under h0, point estimate
default_tail(test::KruskalWallisTest) = :right

function show_params(io::IO, x::KruskalWallisTest, ident)
    println(io, ident, "number of observation in each group: ", x.n_i)
    println(io, ident, "χ²-statistic:                        ", x.H)
    println(io, ident, "rank sums:                           ", x.R_i)
    println(io, ident, "degrees of freedom:                  ", x.df)
    println(io, ident, "adjustment for ties:                 ", x.tie_adjustment)
end

pvalue(x::KruskalWallisTest) = pvalue(Chisq(x.df), x.H; tail=:right)


## helper

# Get H, rank sums, and tie adjustment for Kruskal-Wallis test
function kwstats{T<:Real}(groups::AbstractVector{T}...)
    n_i = [length(g) for g in groups]
    n = sum(n_i)

    # get ranks and adjustment for ties
    (ranks, tieadj) = tiedrank_adj([groups...;])
    C = 1-tieadj/(n^3 - n)

    # compute rank sums
    R_i = Vector{Float64}(length(groups))
    n_end = 0
    for i=1:length(groups)
        R_i[i] = sum(ranks[n_end+1:n_end+n_i[i]])
        n_end += n_i[i]
    end

    # compute test statistic and correct for ties
    H = 12 * sum(R_i.^2./n_i) / (n * (n + 1)) - 3 * (n + 1)
    H /= C

    (H, R_i, C, n_i)
end
