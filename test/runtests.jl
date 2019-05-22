using GFlops
using Test

function my_axpy!(a, x, y)
    @inbounds @simd for i in eachindex(x)
        y[i] += a*x[i]
    end
end

function my_prod(m, v)
    res = similar(v, size(m, 1))

    for i in 1:size(m, 1)
        acc = zero(eltype(m))
        for j in 1:length(v)
            acc += m[i,j]*v[j]
        end
        res[i] = acc
    end
    res
end

import BenchmarkTools: @benchmark
struct FakeResults
    times
end
macro benchmark(e)
    quote
        FakeResults([2.0])
    end
end


@testset "GFlops" begin
    @testset "@count_ops" begin
        let
            N = 100
            a = 2.5
            x = rand(N)
            y = Vector{Float64}(undef, N)

            cnt = @count_ops my_axpy!(a, x, y)
            @test cnt.add64 == 100
            @test cnt.mul64 == 100
            @test GFlops.flop(cnt) == 200


            cnt = @count_ops my_axpy!(pi, $(rand(N)), y)
            @test cnt.add64 == 100
            @test cnt.mul64 == 100
            @test GFlops.flop(cnt) == 200
        end

        let
            N = 100
            m = rand(N, N)
            v = rand(N)
            cnt = @count_ops(my_prod(m, v))
            @test cnt.add64 == N*N
            @test cnt.mul64 == N*N
            @test GFlops.flop(cnt) == 2*N*N
        end
    end

    @testset "@gflops" begin
        let
            N = 100
            a = 2.5
            x = rand(N)
            y = Vector{Float64}(undef, N)

            @test @gflops(my_axpy!(a, x, y))          == N
            @test @gflops(my_axpy!(π, $(rand(N)), y)) == N
        end

        let
            N = 100
            m = rand(N, N)
            v = rand(N)
            @test @gflops(my_prod(m, v)) == N*N
        end
    end
end
