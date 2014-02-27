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

#include "dataflow_order.h++"
#include "node.h++"
#include "node_list.h++"
#include "version.h"
#include <libcodegen/arglist.h++>
#include <libcodegen/builtin.h++>
#include <libcodegen/constant.h++>
#include <libcodegen/fix.h++>
#include <libcodegen/llvm.h++>
#include <libcodegen/op_alu.h++>
#include <libcodegen/op_bits.h++>
#include <libcodegen/op_call.h++>
#include <libcodegen/op_cond.h++>
#include <libcodegen/op_mem.h++>
#include <libcodegen/pointer.h++>
#include <libcodegen/vargs.h++>
#include <libflo/parse.h++>
#include <libflo/infer_widths.h++>
#include <algorithm>
#include <string.h>
#include <string>
#include <map>

using namespace libcodegen;

#ifndef BUFFER_SIZE
#define BUFFER_SIZE 1024
#endif

enum gentype {
    GENTYPE_IR,
    GENTYPE_HEADER,
    GENTYPE_COMPAT,
    GENTYPE_ERROR,
};

/* These generate the different sorts of files that can be produced by
 * the C++ toolchain. */
static int generate_header(const node_list &flo, FILE *f);
static int generate_compat(const node_list &flo, FILE *f);
static int generate_llvmir(const node_list &flo, FILE *f);

/* Produces a class name from a set of Flo nodes. */
static const std::string class_name(const node_list &flo);

/* Sorts a list of nodes by their d, in alphabetical order. */
static std::vector<std::string> sort_by_d(const node_list &flo);

/* Creates a map between a name and the width of that name. */
static std::map<std::string, unsigned>
make_width_map(const node_list &flo);

/* Returns TRUE if the haystack starts with the needle. */
static bool strsta(const std::string haystack, const std::string needle);

int main(int argc, const char **argv)
{
    /* Prints the version if it was asked for. */
    if (argc == 2 && strcmp(argv[1], "--version") == 0) {
        fprintf(stderr, "%s\n", PCONFIGURE_VERSION);
        exit(0);
    }

    /* Prints the help text if it was asked for or if there was no
     * input file given. */
    if (argc == 1 || argc > 3 || strcmp(argv[1], "--help") == 0) {
        fprintf(stderr, "%s: <flo> <type>\n", argv[0]);
        fprintf(stderr, "  Converts a Flo file to LLVM IR\n");
        fprintf(stderr, "  The output will be a drop-in replacement for\n");
        fprintf(stderr, "  Chisel's C++ emulator\n");
        exit(1);
    }

    /* An input filename of "-" means read from stdin. */
    auto infn = strcmp(argv[1], "-") == 0 ? "/dev/stdin" : argv[1];

    /* Look at the second argument to figure out what type to
     * generate. */
    enum gentype type = GENTYPE_ERROR;
    if (strcmp(argv[2], "--ir") == 0)
        type = GENTYPE_IR;
    if (strcmp(argv[2], "--header") == 0)
        type = GENTYPE_HEADER;
    if (strcmp(argv[2], "--compat") == 0)
        type = GENTYPE_COMPAT;

    /* Reads the input file and infers the width of every node. */
    auto flo = libflo::infer_widths(libflo::parse(infn));

    /* Generates the sorts of nodes that the LLVM backend uses (as
     * opposed to the sorts that libflo uses). */
    node_list nodes(flo);

    /* Orders the computation such that the dataflow dependencies will
     * be respected when run serially. */
    auto df = dataflow_order(nodes);

    /* Figures out what sort of output to generate. */
    switch (type) {
    case GENTYPE_IR:
        return generate_llvmir(df, stdout);
    case GENTYPE_HEADER:
        return generate_header(df, stdout);
    case GENTYPE_COMPAT:
        return generate_compat(df, stdout);
    case GENTYPE_ERROR:
        fprintf(stderr, "Unknown generate target '%s'\n", argv[2]);
        fprintf(stderr, "  valid targets are:\n");
        fprintf(stderr, "    --ir:     Generates LLVM IR\n");
        fprintf(stderr, "    --header: Generates a C++ class header\n");
        fprintf(stderr, "    --compat: Generates a C++ compat layer\n");
        abort();
        return 1;
    }

    return 0;
}

int generate_header(const node_list &flo, FILE *f)
{
    /* Figures out the class name, printing that out. */
    fprintf(f, "#include <stdio.h>\n");
    fprintf(f, "#include <stdint.h>\n");
    /* FIXME: Don't depend on Chisel's emulator.h, it kind of
     * defeats the point of doing all this in the first
     * place... */
    fprintf(f, "#include \"emulator.h\"\n");
    fprintf(f, "class %s_t: public mod_t {\n", class_name(flo).c_str());
    fprintf(f, "  public:\n");

    /* Declares the variables that need to be present in the C++
     * header file in order to maintain compatibility with Chisel's
     * output. */
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (!node->exported())
            continue;

        fprintf(f, "    dat_t<%d> %s;\n",
                node->outwid(),
                node->mangled_d().c_str());

        fprintf(f, "    dat_t<%d> %s__prev;\n",
                node->outwid(),
                node->mangled_d().c_str());
    }

    /* Here we write the class methods that exist in Chisel and will
     * be implemented externally by either the compatibility layer or
     * the emitted LLVM IR.  These must exactly match the
     * Chisel-emitted definitions. */
    fprintf(f, "  public:\n");
    fprintf(f, "    void init(bool random_init = false);\n");
    fprintf(f, "    int clock(dat_t<1> reset);\n");
    fprintf(f, "    void clock_lo(dat_t<1> reset);\n");
    fprintf(f, "    void clock_hi(dat_t<1> reset);\n");
    fprintf(f, "    void dump(FILE *file, int clock);\n");

    /* Close the class */
    fprintf(f, "};\n");

    return 0;
}

int generate_compat(const node_list &flo, FILE *f)
{
    auto dut_name = class_name(flo);

    /* The whole point of this is to work around the C++ name
     * mangling. */
    fprintf(f, "extern \"C\" {\n");

    /* Produce accessor functions that can be used to get pointers to
     * particular fields within the C++ class definition.  The idea
     * here is that I can get around C++ name mangling by exporting
     * these as C names. */
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (node->exported() == false)
            continue;

        fprintf(f, "  dat_t<%d> *_llvmflo_%s_ptr(%s_t *d)\n",
                node->outwid(),
                node->mangled_d().c_str(),
                dut_name.c_str()
            );
        fprintf(f, "    { return &(d->%s); }\n", node->mangled_d().c_str());
    }

    /* Figure out the largest dat_t used by this design, so we can
     * build a host of functions that allow dat_t accesses. */
    size_t largest_dat_t = 0;
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;
        if (node->outwid() > largest_dat_t)
            largest_dat_t = node->outwid();
    }

    /* Goes ahead and emits a dat_t accessor function for each and
     * every dat_t size that's used by this module. */
    auto dats_emitted = new bool[largest_dat_t + 1];
    for (size_t i = 0; i <= largest_dat_t; ++i) {
        dats_emitted[i] = false;
    }

    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        /* Checks to see if this accessor width has already been
         * initialized, in which case we don't initialize the accessor
         * functions to avoid duplicate symbols. */
        if (node->outwid() > largest_dat_t) {
            fprintf(stderr, "node's width of %d is larger than %lu\n",
                    node->outwid(),
                    largest_dat_t);

            abort();
        }
        if (dats_emitted[node->outwid()] == true)
            continue;
        dats_emitted[node->outwid()] = true;

        /* Emits a getter and a setter for dat_ts of this width. */
        fprintf(f, "  void _llvmdat_%d_get(const dat_t<%d> *d, uint64_t *a)\n",
                node->outwid(), node->outwid());
        fprintf(f, "  {\n");
        for (size_t i = 0; i < (node->outwid() + 63) / 64; ++i)
            fprintf(f, "    a[%lu] = d->values[%lu];\n", i, i);
        fprintf(f, "  }\n");

        fprintf(f, "  void _llvmdat_%d_set(dat_t<%d> *d, const uint64_t *a)\n",
                node->outwid(), node->outwid());
        fprintf(f, "  {\n");
        for (size_t i = 0; i < (node->outwid() + 63) / 64; ++i)
            fprintf(f, "    d->values[%lu] = a[%lu];\n", i, i);
        fprintf(f, "  }\n");
    }

    /* Here's where we elide the last bits of name mangling: these
     * functions wrap some non-mangled IR-generated names that
     * actually implement the functions required by Chisel's C++
     * interface. */
    fprintf(f, "  void _llvmflo_%s_init(%s_t *p, bool r);\n",
            dut_name.c_str(), dut_name.c_str());

    fprintf(f, "  void _llvmflo_%s_clock_lo(%s_t *p, bool r);\n",
            dut_name.c_str(), dut_name.c_str());

    fprintf(f, "  void _llvmflo_%s_clock_hi(%s_t *p, bool r);\n",
            dut_name.c_str(), dut_name.c_str());

    /* End the 'extern "C"' block above. */
    fprintf(f, "};\n");

    /* The clock function just calls the other two clock functions. */
    fprintf(f, "int %s_t::clock(dat_t<1> rd)\n", dut_name.c_str());
    fprintf(f, "  { clock_hi(rd); clock_lo(rd); return 0; }\n");

    /* Actually define the (non mangled) implementation of the Chisel
     * C++ interface, which in fact only calls the LLVM-generated
     * functions. */
    fprintf(f, "void %s_t::clock_lo(dat_t<1> rd)\n", dut_name.c_str());
    fprintf(f, "  { _llvmflo_%s_clock_lo(this, rd.to_ulong()); }\n",
            dut_name.c_str());

    /* init just sets everything to zero, which is easy to do in C++
     * (it'll be fairly short). */
    fprintf(f, "void %s_t::init(bool r)\n{\n", dut_name.c_str());
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (node->exported() == false)
            continue;

        fprintf(f, "  this->%s = 0;\n", node->mangled_d().c_str());
    }
    fprintf(f, "}\n");

    /* clock_hi just copies data around and therefor is simplest to
     * stick in C++ -- using LLVM IR doesn't really gain us anything
     * here. */
    fprintf(f, "void %s_t::clock_hi(dat_t<1> rd)\n{\n", dut_name.c_str());
    fprintf(f, "  bool r = rd.to_ulong();\n");
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (node->exported() == false)
            continue;

        if (node->opcode() != libflo::opcode::REG)
            continue;

        fprintf(f, "  %s = %s;\n",
                node->mangled_d( ).c_str(),
                node->mangled_s(1).c_str()
            );
    }
    fprintf(f, "}\n");

    /* VCD dumping is implemented directly in C++ here because I don't
     * really see a reason not to. */
    fprintf(f, "void %s_t::dump(FILE *f, int cycle)\n{\n", dut_name.c_str());

    /* On the first cycle we need to write out the VCD header file. */
    size_t vcdtmp = 0;
    fprintf(f, "  if (cycle == 0) {\n");
    fprintf(f, "    fprintf(f, \"$timescale 1ps $end\\n\");\n");
    
    std::string last_path = "";
    auto sorted = sort_by_d(flo);
    auto width_map = make_width_map(flo);
    std::map<std::string, std::string> short_name;
    for (auto it = sorted.begin(); it != sorted.end(); ++it) {
        char buffer[BUFFER_SIZE];
        snprintf(buffer, BUFFER_SIZE, "%s", (*it).c_str());

        /* Here's where we figure out where in the module heirarchy
         * this node is. */
        char *module = buffer;
        char *signal = buffer;
        for (size_t i = 0; i < strlen(buffer); i++)
            if (buffer[i] == ':')
                signal = buffer + i;

        /* These have no "::" in them, which means they're not
         * globally visible. */
        if (module == signal)
            continue;

        /* The module seperator can be either ":" or "::".  Detect
         * which one is actually generated and demangle the name
         * correctly. */
        if (signal[-1] == ':')
            signal[-1] = '\0';
        signal[0] = '\0';
        signal++;

        /* Figure out if we're going up or down a module and perform
         * that move. */
        if (strsta(last_path, module) && strsta(module, last_path)) {
        } else if (strsta(last_path, module)) {
            fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");
        } else if (strsta(module, last_path)) {
            /* Determine a slightly shorter name for the module, which
             * is what VCD uses.  This is just the last component of
             * the module name, the remainder can be determined by the
             * hierarchy. */
            char *lastmodule = module;
            for (size_t i = 0; i < strlen(module); i++)
                if (module[i] == ':')
                    lastmodule = module + i;
            if (*lastmodule == ':')
                lastmodule++;

            fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
                    lastmodule);
        }

        /* Obtains a short name for this node and stores it for
         * later. */
        char sn[BUFFER_SIZE];
        snprintf(sn, BUFFER_SIZE, "N%lu", vcdtmp++);
        short_name[*it] = sn;

        /* After changing modules, go ahead and output the wire. */
        fprintf(f, "    fprintf(f, \"$var wire %d %s %s $end\\n\");\n",
                width_map.find(*it)->second,
                sn,
                signal
            );

        /* The last path is always equal to the current one -- note
         * that sometimes this won't do anything as it'll be the same,
         * but this strictly enforces this condition. */
        last_path = module;
    }

    size_t colon_count = 0;
    for (size_t i = 0; i < strlen(last_path.c_str()); i++)
        if (last_path[i] == ':')
            colon_count++;

    for (size_t i = 0; i <= (colon_count / 2); i++)
        fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");

    fprintf(f, "  fprintf(f, \"$enddefinitions $end\\n\");\n");
    fprintf(f, "  fprintf(f, \"$dumpvars\\n\");\n");
    fprintf(f, "  fprintf(f, \"$end\\n\");\n");

    fprintf(f, "  }\n");

    fprintf(f, "  fprintf(f, \"#%%lu\\n\", cycle);\n");

    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (node->exported() == false)
            continue;

        fprintf(f,
                "  if ((cycle == 0) || (%s__prev != %s).to_ulong()) {\n",
                node->mangled_d().c_str(),
                node->mangled_d().c_str()
            );

        fprintf(f, "    dat_dump(f, %s, \"%s\");\n",
                node->mangled_d().c_str(),
                short_name.find(node->d())->second.c_str()
            );

        fprintf(f, "    %s__prev = %s;\n",
                node->mangled_d().c_str(),
                node->mangled_d().c_str()
            );

        fprintf(f, "  }\n");
    }

    fprintf(f, "}\n");

    return 0;
}

int generate_llvmir(const node_list &flo, FILE *f)
{
    auto dut_name = class_name(flo);

    /* This writer outputs LLVM IR to the given file. */
    llvm out(f);

    /* Generate declarations for some external functions that get used
     * by generated code below. */
    function< builtin<void>,
              arglist2< pointer< builtin<char> >,
                        vargs
                        >
              >
        extern_printf("printf");
    out.declare(extern_printf);

    function< builtin<void>,
              arglist5< pointer< builtin<char> >,
                        builtin<char>,
                        builtin<uint64_t>,
                        builtin<uint32_t>,
                        builtin<bool>
                        >
              >
        extern_memset("llvm.memset.p0i8.i64");
    out.declare(extern_memset);

    /* These symbols are generated by the compatibility layer but
     * still need declarations so LLVM can check their types.  Note
     * that here I'm just manually handling this type safety, which is
     * probably nasty... */
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (node->exported() == false)
            continue;

        out.declare(node->ptr_func());
    }

    /* FIXME: This should all go away.  Instead I'm just going to
     * directly emit the get/set code in the C++ shim.  This way I'll
     * have a unique function for each variable. */
    size_t largest_dat_t = 0;
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;
        if (node->outwid() > largest_dat_t)
            largest_dat_t = node->outwid();
    }
    auto dats_emitted = new bool[largest_dat_t + 1];
    for (size_t i = 0; i <= largest_dat_t; ++i) {
        dats_emitted[i] = false;
    }
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        /* Checks to see if this accessor width has already been
         * initialized, in which case we don't initialize the accessor
         * functions to avoid duplicate symbols. */
        if (node->outwid() > largest_dat_t) {
            fprintf(stderr, "node's width of %d is larger than %lu\n",
                    node->outwid(),
                    largest_dat_t);

            abort();
        }
        if (dats_emitted[node->outwid()] == true)
            continue;
        dats_emitted[node->outwid()] = true;

        /* Emits a getter and a setter for dat_ts of this width. */
        fprintf(f, "declare void @_llvmdat_%d_get(i8* %%dut, i64* %%a)\n",
                node->outwid());
        fprintf(f, "declare void @_llvmdat_%d_set(i8* %%dut, i64* %%a)\n",
                node->outwid());
    }

    /* Here we generate clock_lo, which performs all the logic
     * operations but does not perform any register writes.  In order
     * to do this we'll have to walk through the computation in
     * dataflow order. */
    function< builtin<void>,
              arglist2<pointer<builtin<void>>,
                       builtin<bool>
                       >
              >
        clock_lo("_llvmflo_%s_clock_lo", dut_name.c_str());
    {
        auto dut = pointer<builtin<void>>("dut");
        auto dut_vec = std::vector<value*>();
        dut_vec.push_back(&dut);

        auto rst = builtin<bool>("rst");
        auto rst_vec = std::vector<value*>();
        rst_vec.push_back(&rst);

        auto lo = out.define(clock_lo, {&dut, &rst});

        /* The code is already in dataflow order so all we need to do
         * is emit the computation out to LLVM. */
        for (auto it = flo.nodes(); !it.done(); ++it) {
            auto node = *it;

            /* This contains a count of the number of i64-wide
             * operations that need to be performed in order to make
             * this operation succeed. */
            auto i64cnt = constant<uint32_t>((node->outwid() + 63) / 64);

            lo->comment(" *** Chisel Node: %s", node->to_string().c_str());

            bool nop = false;
            switch (node->opcode()) {
                /* The following nodes are just no-ops in this phase, they
                 * only show up in the clock_hi phase. */
            case libflo::opcode::OUT:
                lo->operate(mov_op(node->dv(), node->sv(0)));
                break;

            case libflo::opcode::ADD:
                lo->operate(add_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::AND:
                lo->operate(and_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::CAT:
            {
                auto sw = constant<uint64_t>(node->outwid() - node->width());
                auto o = constant<uint64_t>(node->width());

                auto d = node->dv();
                auto s = fix_t(sw, node->sv(0).name());
                auto t = node->sv(1);

                auto se = fix_t(node->outwid());
                auto te = fix_t(node->outwid());
                lo->operate(zero_ext_op(se, s));
                lo->operate(zero_ext_op(te, t));

                auto ss = fix_t(node->outwid());
                lo->operate(lsh_op(ss, se, o));

                lo->operate(or_op(d, te, ss));

                break;
            }

            case libflo::opcode::EQ:
                lo->operate(cmp_eq_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::GTE:
                lo->operate(cmp_gte_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::LT:
                lo->operate(cmp_lt_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::MOV:
                lo->operate(mov_op(node->dv(), node->sv(0)));
                break;

            case libflo::opcode::MUX:
                lo->operate(mux_op(node->dv(),
                                   node->sv(0),
                                   node->sv(1),
                                   node->sv(2)
                                ));
                break;

            case libflo::opcode::NOT:
                lo->operate(not_op(node->dv(), node->sv(0)));
                break;

            case libflo::opcode::OR:
                lo->operate(or_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::IN:
            case libflo::opcode::REG:
            {
                auto ptr64 = pointer<builtin<uint64_t>>();
                auto ptrC = pointer<builtin<void>>();

                /* Obtain a pointer to the C++ structure's internal
                 * structure definiton so it can be converted into an
                 * LLVM operation. */
                lo->operate(alloca_op(ptr64, i64cnt));
                lo->operate(call_op(ptrC, node->ptr_func(), dut_vec));
                lo->operate(call_op(node->get_func(), {&ptrC, &ptr64}));

                /* Here we generate the internal temporary values.
                 * This series of shift/add operations will probably
                 * be compiled into NOPs by the LLVM optimizer. */
                auto ptrs = std::vector<pointer<builtin<uint64_t>>>(i64cnt);
                for (size_t i = 0; i < i64cnt; i++) {
                    auto index = constant<size_t>(i);
                    lo->operate(index_op(ptrs[i], ptr64, index));
                }

                auto loads = std::vector<builtin<uint64_t>>(i64cnt);
                for (size_t i = 0; i < i64cnt; ++i) {
                    lo->operate(load_op(loads[i], ptrs[i]));
                }

                auto extended = std::vector<fix_t>();
                for (size_t i = 0; i < i64cnt; ++i) {
                    /* We need this push here because every one of
                     * these temporaries needs a new name which means
                     * the copy constructor can't be used.  The
                     * default constructor can't be used because we
                     * need to tag each fix with a width. */
                    extended.push_back(fix_t(node->width()));
                    lo->operate(zext_trunc_op(extended[i], loads[i]));
                }

                auto shifted = std::vector<fix_t>();
                for (size_t i = 0; i < i64cnt; i++) {
                    shifted.push_back(fix_t(node->width()));
                    auto offset = constant<uint32_t>(i * 64);
                    lo->operate(lsh_op(shifted[i], extended[i], offset));
                }

                auto ored = std::vector<fix_t>();
                for (size_t i = 0; i < i64cnt; ++i) {
                    ored.push_back(fix_t(node->width()));
                    if (i == 0) {
                        lo->operate(mov_op(ored[i], shifted[i]));
                    } else {
                        lo->operate(or_op(ored[i], shifted[i], ored[i-1]));
                    }
                }

                lo->operate(mov_op(node->dv(), ored[i64cnt-1]));

                break;
            }

            case libflo::opcode::RSH:
            {
                auto shifted = fix_t(node->width());
                lo->operate(lrsh_op(shifted, node->sv(0), node->sv(1)));
                lo->operate(zext_trunc_op(node->dv(), shifted));
                break;
            }

            case libflo::opcode::RST:
                lo->operate(unsafemov_op(node->dv(), rst));
                break;

            case libflo::opcode::SUB:
                lo->operate(sub_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::XOR:
                lo->operate(xor_op(node->dv(), node->sv(0), node->sv(1)));
                break;

            case libflo::opcode::RND:
            case libflo::opcode::EAT:
            case libflo::opcode::LIT:
            case libflo::opcode::MSK:
            case libflo::opcode::LD:
            case libflo::opcode::NEQ:
            case libflo::opcode::ARSH:
            case libflo::opcode::LSH:
            case libflo::opcode::ST:
            case libflo::opcode::MEM:
            case libflo::opcode::NOP:
            case libflo::opcode::MUL:
            case libflo::opcode::LOG2:
            case libflo::opcode::NEG:
            case libflo::opcode::RD:
            case libflo::opcode::WR:
                fprintf(stderr, "Unable to compute node '%s'\n",
                        libflo::opcode_to_string(node->opcode()).c_str());
                abort();
                break;
            }

            /* Every node that's in the Chisel header gets stored after
             * its cooresponding computation, but only when the node
             * appears in the Chisel header. */
            if (node->exported() == true && nop == false) {
                lo->comment("  Writeback\n");

                /* This generates a pointer that can be passed to C++,
                 * in other words, an array-of-uints. */
                auto ptr64 = pointer<builtin<uint64_t>>();
                lo->operate(alloca_op(ptr64, i64cnt));

                /* Here we generate the internal temporary values.
                 * This series of shift/add operations will probably
                 * be compiled into NOPs by the LLVM optimizer. */
                auto shifted = std::vector<fix_t>();
                for (size_t i = 0; i < i64cnt; ++i) {
                    shifted.push_back(fix_t(node->outwid()));
                    auto offset = constant<uint32_t>(i * 64);
                    lo->operate(lrsh_op(shifted[i], node->dv(), offset));
                }

                auto trunced = std::vector<builtin<uint64_t>>(i64cnt);
                for (size_t i = 0; i < i64cnt; ++i) {
                    lo->operate(zext_trunc_op(trunced[i], shifted[i]));
                }

                auto ptrs = std::vector<pointer<builtin<uint64_t>>>(i64cnt);
                for (size_t i = 0; i < i64cnt; ++i) {
                    auto index = constant<size_t>(i);
                    lo->operate(index_op(ptrs[i], ptr64, index));
                }

                for (size_t i = 0; i < i64cnt; ++i) {
                    lo->operate(store_op(ptrs[i], trunced[i]));
                }

                /* Here we fetch the actual C++ pointer that can be
                 * used to move this signal's data out. */
                auto ptrC = pointer<builtin<void>>();
                lo->operate(call_op(ptrC, node->ptr_func(), dut_vec));
                lo->operate(call_op(node->set_func(), {&ptrC, &ptr64}));
            }
        }

        fprintf(f, "  ret void\n");
    }

    return 0;
}

const std::string class_name(const node_list &flo)
{
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (strstr(node->d().c_str(), ":") == NULL)
            continue;

        char buffer[BUFFER_SIZE];
        strncpy(buffer, node->d().c_str(), BUFFER_SIZE);
        strstr(buffer, ":")[0] = '\0';
        return buffer;
    }

    fprintf(stderr, "Unable to obtain class name\n");
    abort();
    return "";
}

std::vector<std::string> sort_by_d(const node_list &flo)
{
    std::vector<std::string> out;

    for (auto it = flo.nodes(); !it.done(); ++it)
        out.push_back((*it)->d());

    std::sort(out.begin(), out.end());

    return out;
}

std::map<std::string, unsigned> make_width_map(const node_list &flo)
{
    std::map<std::string, unsigned> out;

    for (auto it = flo.nodes(); !it.done(); ++it)
        out[(*it)->d()] = (*it)->outwid();

    return out;
}

bool strsta(const std::string haystack, const std::string needle)
{
    const char *h = haystack.c_str();
    const char *n = needle.c_str();

    return (strncmp(h, n, strlen(n)) == 0);
}
