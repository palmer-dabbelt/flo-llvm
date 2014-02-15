/*
 * Copyright (C) 2014 Palmer Dabbelt
 *   <palmer.dabbelt@eecs.berkeley.edu>
 *
 * This file is part of flo-llvm.
 *
 * flo-llvm is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * flo-llvm is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with flo-llvm.  If not, see
 * <http://www.gnu.org/licenses/>.
 */

#ifndef LIBCODEGEN__ARGLIST_HXX
#define LIBCODEGEN__ARGLIST_HXX

#include <string>
#include <vector>

/* This is how we deal with argument lists to functions.  I'd really
 * like to have this be a single class rather than a whole bunch, but
 * I don't understand C++'s template metaprogramming well enough to
 * write that while I'm on an airplane without internet access... */
namespace libcodegen {
    template<class A>
    class arglist1 {
    public:
        static std::vector<std::string> as_llvm(void)
            {
                std::vector<std::string> out;
                out.push_back(A::as_llvm());
                return out;
            }
    };

    template<class A, class B>
    class arglist2 {
    public:
        static std::vector<std::string> as_llvm(void)
            {
                std::vector<std::string> out;
                out.push_back(A::as_llvm());
                out.push_back(B::as_llvm());
                return out;
            }
    };

    template<class A, class B, class C>
    class arglist3 {
    public:
        static std::vector<std::string> as_llvm(void)
            {
                std::vector<std::string> out;
                out.push_back(A::as_llvm());
                out.push_back(B::as_llvm());
                out.push_back(C::as_llvm());
                return out;
            }
    };

    template<class A, class B, class C, class D>
    class arglist4 {
    public:
        static std::vector<std::string> as_llvm(void)
            {
                std::vector<std::string> out;
                out.push_back(A::as_llvm());
                out.push_back(B::as_llvm());
                out.push_back(C::as_llvm());
                out.push_back(D::as_llvm());
                return out;
            }
    };

    template<class A, class B, class C, class D, class E>
    class arglist5 {
    public:
        static std::vector<std::string> as_llvm(void)
            {
                std::vector<std::string> out;
                out.push_back(A::as_llvm());
                out.push_back(B::as_llvm());
                out.push_back(C::as_llvm());
                out.push_back(D::as_llvm());
                out.push_back(E::as_llvm());
                return out;
            }
    };
}

#endif
