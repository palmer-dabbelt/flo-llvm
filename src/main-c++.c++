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
#include "mangle_name.h++"
#include "version.h"
#include <libflo/parse.h++>
#include <libflo/infer_widths.h++>
#include <algorithm>
#include <string.h>
#include <string>

using namespace libflo;

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
static int generate_header(const libflo::node_list &flo, FILE *f);
static int generate_compat(const libflo::node_list &flo, FILE *f);
static int generate_llvmir(const libflo::node_list &flo, FILE *f);

/* Produces the LLVM-internal name given a string -- essentially this
 * is just yet another form of name mangling.  The prefix argument is
 * used when you want to generate a group of related names that are
 * gaurnteed to not conflict. */
static const std::string llvm_name(const std::string chisel_name,
                                   const std::string prefix = "");

/* Produces a class name from a set of Flo nodes. */
static const std::string class_name(const libflo::node_list &flo);

/* Sorts a list of nodes by their d, in alphabetical order. */
static std::vector<std::string> sort_by_d(const node_list &flo);

/* Creates a map between a name and the width of that name. */
static std::map<std::string, unsigned> make_width_map(const node_list &flo);

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

    /* Figures out what sort of output to generate. */
    switch (type) {
    case GENTYPE_IR:
        return generate_llvmir(flo, stdout);
    case GENTYPE_HEADER:
        return generate_header(flo, stdout);
    case GENTYPE_COMPAT:
        return generate_compat(flo, stdout);
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

int generate_header(const libflo::node_list &flo, FILE *f)
{
    /* Figures out the class name, printing that out. */
    fprintf(f, "#include <stdio.h>\n");
    fprintf(f, "#include <stdint.h>\n");
    /* FIXME: Don't depend on Chisel's emulator.h, it kind of
     * defeats the point of doing all this in the first
     * place... */
    fprintf(f, "#include <emulator.h>\n");
    fprintf(f, "class %s_t {\n", class_name(flo).c_str());
    fprintf(f, "  public:\n");

    /* Declares the variables that need to be present in the C++
     * header file in order to maintain compatibility with Chisel's
     * output. */
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        fprintf(f, "    dat_t<%d> %s;\n",
                node->outwid(),
                mangled_name.c_str());

        fprintf(f, "    dat_t<%d> _vcdshadow_%s;\n",
                node->outwid(),
                mangled_name.c_str());
    }

    /* Here we write the class methods that exist in Chisel and will
     * be implemented externally by either the compatibility layer or
     * the emitted LLVM IR.  These must exactly match the
     * Chisel-emitted definitions. */
    fprintf(f, "  public:\n");
    fprintf(f, "    void init(bool random_init);\n");
    fprintf(f, "    void clock_lo(bool reset);\n");
    fprintf(f, "    void clock_hi(bool reset);\n");
    fprintf(f, "    void dump(FILE *file, size_t clock);\n");

    /* Close the class */
    fprintf(f, "};\n");

    return 0;
}

int generate_compat(const libflo::node_list &flo, FILE *f)
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

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        fprintf(f, "  dat_t<%d> *_llvmflo_%s_ptr(%s_t *d)\n",
                node->outwid(),
                mangled_name.c_str(),
                dut_name.c_str()
            );
        fprintf(f, "    { return &(d->%s); }\n", mangled_name.c_str());
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

    /* Actually define the (non mangled) implementation of the Chisel
     * C++ interface, which in fact only calls the LLVM-generated
     * functions. */
    fprintf(f, "void %s_t::init(bool r)\n", dut_name.c_str());
    fprintf(f, "  { _llvmflo_%s_init(this, r); }\n", dut_name.c_str());

    fprintf(f, "void %s_t::clock_lo(bool r)\n", dut_name.c_str());
    fprintf(f, "  { _llvmflo_%s_clock_lo(this, r); }\n", dut_name.c_str());

    /* clock_hi just copies data around and therefor is simplest to
     * stick in C++ -- using LLVM IR doesn't really gain us anything
     * here. */
    fprintf(f, "void %s_t::clock_hi(bool r)\n{\n", dut_name.c_str());
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        if (node->opcode() != opcode::REG)
            continue;

        fprintf(f, "  %s = %s;\n",
                mangle_name(node->d( )).second.c_str(),
                mangle_name(node->s(1)).second.c_str()
            );
    }
    fprintf(f, "}\n");

    /* VCD dumping is implemented directly in C++ here because I don't
     * really see a reason not to. */
    fprintf(f, "void %s_t::dump(FILE *f, size_t cycle)\n{\n", dut_name.c_str());

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

        /* The module seperator is a "::", make sure that's true. */
        if (signal[-1] != ':') {
            fprintf(stderr, "Module seperator without '::' in '%s'\n", buffer);
            abort();
        }

        signal[-1] = '\0';
        signal++;

        /* Figure out if we're going up or down a module and perform
         * that move. */
        if (strsta(last_path, module) && strsta(module, last_path)) {
        } else if (strsta(last_path, module)) {
            fprintf(f, "    fprintf(f, \"$upscope $end\\n\");\n");
        } else if (strsta(module, last_path)) {
            fprintf(f, "    fprintf(f, \"$scope module %s $end\\n\");\n",
                    module);
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

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        fprintf(f,
                "  if ((cycle == 0) || (_vcdshadow_%s != %s).to_ulong()) {\n",
                mangled_name.c_str(),
                mangled_name.c_str()
            );

        fprintf(f, "    dat_dump(f, %s, \"%s\");\n",
                mangled_name.c_str(),
                short_name.find(node->d())->second.c_str()
            );

        fprintf(f, "    _vcdshadow_%s = %s;\n",
                mangled_name.c_str(),
                mangled_name.c_str()
            );

        fprintf(f, "  }\n");
    }

    fprintf(f, "}\n");

    return 0;
}

int generate_llvmir(const libflo::node_list &flo, FILE *f)
{
    auto dut_name = class_name(flo);

    fprintf(f, "declare void @abort()\n");
    fprintf(f, "declare void @printf(i8* %%f, ...)\n");
    fprintf(f, "declare void @llvm.memset.p0i8.i64(i8*, i8, i64, i32, i1)\n");

    /* These symbols are generated by the compatibility layer but
     * still need declarations so LLVM can check their types.  Note
     * that here I'm just manually handling this type safety, which is
     * probably nasty... */
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        fprintf(f, "declare i8* @_llvmflo_%s_ptr(i8* %%dut)\n",
                mangled_name.c_str());
    }

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

    /* Write the init function, which sets every node to zero.  Note
     * that random initialization is not currently supported. */
    fprintf(f, "define void @_llvmflo_%s_init(i8* %%dut, i1 %%rnd) {\n",
            dut_name.c_str());

    /* Generates a large array of zeros on the stack that can be used
     * for initializing dat_ts to zero. */
    fprintf(f, "  %%zeros = alloca i64, i32 %lu\n", (largest_dat_t + 63) / 64);
    fprintf(f, "  %%zeros8 = bitcast i64* %%zeros to i8*\n");
    fprintf(f, "  call void @llvm.memset.p0i8.i64(i8* %%zeros8, i8 0, i64 %lu, i32 0, i1 0)\n",
            (largest_dat_t + 63) / 64);

    uint64_t tmp = 0;
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        auto mangled_name_p = mangle_name(node->d());
        if (mangled_name_p.first != true)
            continue;
        auto mangled_name = mangled_name_p.second;

        fprintf(f, "  %%T%lu = call i8* @_llvmflo_%s_ptr(i8* %%dut)\n",
                tmp, mangled_name.c_str());
        fprintf(f, "  call void @_llvmdat_%u_set(i8* %%T%lu, i64* %%zeros)\n",
                node->outwid(), tmp);

        tmp++;
    }

    fprintf(f, "  ret void\n");
    fprintf(f, "}\n");

    /* Here we generate clock_lo, which performs all the logic
     * operations but does not perform any register writes.  In order
     * to do this we'll have to walk through the computation in
     * dataflow order. */
    fprintf(f, "define void @_llvmflo_%s_clock_lo(i8* %%dut, i1 %%rst) {\n",
            dut_name.c_str());

    /* Schedule the computation in dataflow order and emit every
     * node's representation in LLVM IR.  Note that loads from the C++
     * emulator wrapper are just scheduled directly in place here. */
    auto df = dataflow_order(flo);
    for (auto it = df.begin(); it != df.end(); ++it) {
        auto node = *it;

        /* Here we don't care if the mangled name was changed, they're
         * all going to end up in the circuit eventually. */
        auto mangled_name_p = mangle_name(node->d());
        auto mangled_name = mangled_name_p.second;

        fprintf(f, "  ; Chisel Node: ");
        node->writeln(f);

        bool nop = false;
        switch (node->opcode()) {
            /* The following nodes are just no-ops in this phase, they
             * only show up in the clock_hi phase. */
        case opcode::OUT:
            fprintf(f, "    %s = or i%d %s, %s\n",
                    llvm_name(node->d()).c_str(),
                    node->outwid(),
                    llvm_name(node->s(0)).c_str(),
                    llvm_name(node->s(0)).c_str()
                );
            break;

        case opcode::ADD:
            fprintf(f, "    %s = add i%d %s, %s\n",
                    llvm_name(node->d()).c_str(),
                    node->outwid(),
                    llvm_name(node->s(0)).c_str(),
                    llvm_name(node->s(1)).c_str()
                );
            break;

        case opcode::AND:
            fprintf(f, "    %s = and i%d %s, %s\n",
                    llvm_name(node->d()).c_str(),
                    node->outwid(),
                    llvm_name(node->s(0)).c_str(),
                    llvm_name(node->s(1)).c_str()
                );
            break;

        case opcode::MUX:
            fprintf(f, "    %s = select i1 %s, i%d %s, i%d %s\n",
                    llvm_name(node->d()).c_str(),
                    llvm_name(node->s(0)).c_str(),
                    node->outwid(),
                    llvm_name(node->s(1)).c_str(),
                    node->outwid(),
                    llvm_name(node->s(2)).c_str()
                );
            break;

        case opcode::REG:
            fprintf(f, "    %s = alloca i64, i32 %u\n",
                    llvm_name(node->d(), "rptr64").c_str(),
                    (node->outwid() + 63) / 64
                );

            fprintf(f, "    %s = call i8* @_llvmflo_%s_ptr(i8* %%dut)\n",
                    llvm_name(node->d(), "rptrC").c_str(),
                    mangle_name(node->d()).second.c_str()
                );

            fprintf(f, "    call void @_llvmdat_%u_get(i8* %s, i64* %s)\n",
                    node->outwid(),
                    llvm_name(node->d(), "rptrC").c_str(),
                    llvm_name(node->d(), "rptr64").c_str()
                );

            /* FIXME: Are these three cases really necessary?  It
             * feels like they might not actually be... */
            if (node->outwid() < 64) {
                fprintf(f, "    %%T__%lu = load i64* %s\n",
                        tmp,
                        llvm_name(node->d(), "rptr64").c_str()
                    );

                fprintf(f, "    %s = trunc i64 %%T__%lu to i%u\n",
                        llvm_name(node->d()).c_str(),
                        tmp,
                        node->outwid()
                    );

                tmp++;
            } else if (node->outwid() == 64) {
                fprintf(f, "    %s = load i64* %s\n",
                        llvm_name(node->d()).c_str(),
                        llvm_name(node->d(), "rptr64").c_str()
                    );
            } else {
                fprintf(f, "    %%T__%lu = or i%d 0, 0\n",
                        tmp,
                        node->outwid()
                    );
                tmp++;

                for (unsigned i = 0; i < (node->outwid() + 63) / 64; ++i) {
                    fprintf(f,
                            "     %%T__%lu = getelementptr i64* %s, i64 %d\n",
                            tmp,
                            llvm_name(node->d(), "rptr64").c_str(),
                            i
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = load i64* %%T__%lu\n",
                            tmp,
                            tmp - 1
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = zext i64 %%T__%lu to i%d\n",
                            tmp,
                            tmp - 1,
                            node->outwid()
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = shl i%d %%T__%lu, %d\n",
                            tmp,
                            node->outwid(),
                            tmp - 1,
                            i * 64
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = or i%d %%T__%lu, %%T__%lu\n",
                            tmp,
                            node->outwid(),
                            tmp - 1,
                            tmp - 5
                        );
                    tmp++;
                }

                fprintf(f, "    %s = or i%d %%T__%lu, %%T__%lu\n",
                        llvm_name(node->d()).c_str(),
                        node->outwid(),
                        tmp - 1,
                        tmp - 1
                    );
            }

            break;                    

        case opcode::RST:
            fprintf(f, "    %s = or i1 %%rst, %%rst\n",
                    llvm_name(node->d()).c_str()
                );
            break;

        case opcode::IN:
        case opcode::RND:
        case opcode::EAT:
        case opcode::SUB:
        case opcode::LT:
        case opcode::NOT:
        case opcode::OR:
        case opcode::EQ:
        case opcode::LIT:
        case opcode::CAT:
        case opcode::RSH:
        case opcode::MSK:
        case opcode::LD:
        case opcode::NEQ:
        case opcode::ARSH:
        case opcode::LSH:
        case opcode::XOR:
        case opcode::ST:
        case opcode::MEM:
        case opcode::GTE:
        case opcode::MOV:
            fprintf(stderr, "Unable to compute node '%s'\n",
                    libflo::opcode_to_string(node->opcode()).c_str());
            abort();
            break;
        }

        /* Every node that's in the Chisel header gets stored after
         * its cooresponding computation, but only when the node
         * appears in the Chisel header. */
        if (mangled_name_p.first == true && nop == false) {
            fprintf(f, "    %s = alloca i64, i32 %u\n",
                    llvm_name(node->d(), "ptr64").c_str(),
                    (node->outwid() + 63) / 64
                );

            fprintf(f, "    %s = call i8* @_llvmflo_%s_ptr(i8* %%dut)\n",
                    llvm_name(node->d(), "ptrC").c_str(),
                    mangle_name(node->d()).second.c_str()
                );

            /* FIXME: Are these three cases really necessary?  It
             * feels like they might not actually be... */
            if (node->outwid() < 64) {
                fprintf(f, "    %%T__%lu = zext i%d %s to i64\n",
                        tmp,
                        node->outwid(),
                        llvm_name(node->d()).c_str()
                    );

                fprintf(f, "    store i64 %%T__%lu, i64* %s\n",
                        tmp,
                        llvm_name(node->d(), "ptr64").c_str()
                    );

                tmp++;
            } else if (node->outwid() == 64) {
                fprintf(f, "    store i64 %s, i64* %s\n",
                        llvm_name(node->d()).c_str(),
                        llvm_name(node->d(), "ptr64").c_str()
                    );
            } else {
                for (unsigned i = 0; i < (node->outwid() + 63) / 64; ++i) {
                    fprintf(f,
                            "     %%T__%lu = getelementptr i64* %s, i64 %d\n",
                            tmp,
                            llvm_name(node->d(), "ptr64").c_str(),
                            i
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = lshr i%d %s, %d\n",
                            tmp,
                            node->outwid(),
                            llvm_name(node->d()).c_str(),
                            i * 64
                        );
                    tmp++;

                    fprintf(f, "      %%T__%lu = trunc i%d %%T__%lu to i64\n",
                            tmp,
                            node->outwid(),
                            tmp - 1
                        );
                    tmp++;

                    fprintf(f, "      store i64 %%T__%lu, i64* %%T__%lu\n",
                            tmp - 1,
                            tmp - 3
                        );
                }
            }

            fprintf(f, "    call void @_llvmdat_%u_set(i8* %s, i64* %s)\n",
                    node->outwid(),
                    llvm_name(node->d(), "ptrC").c_str(),
                    llvm_name(node->d(), "ptr64").c_str()
                );
        }
    }

    fprintf(f, "  ret void\n");
    fprintf(f, "}\n");

    return 0;
}

const std::string class_name(const libflo::node_list &flo)
{
    for (auto it = flo.nodes(); !it.done(); ++it) {
        auto node = *it;

        if (strstr(node->d().c_str(), "::") == NULL)
            continue;

        char buffer[BUFFER_SIZE];
        strncpy(buffer, node->d().c_str(), BUFFER_SIZE);
        strstr(buffer, "::")[0] = '\0';
        return buffer;
    }

    abort();
    return "";
}

const std::string llvm_name(const std::string chisel_name,
                            const std::string prefix)
{
    char buffer[BUFFER_SIZE];
    snprintf(buffer, BUFFER_SIZE, "%s", chisel_name.c_str());
    if (isdigit(buffer[0]))
        return chisel_name;

    auto mangled = mangle_name(chisel_name).second;
    snprintf(buffer, BUFFER_SIZE, "%%C%s__%s",
             prefix.c_str(), mangled.c_str());
    return buffer;
}

std::vector<std::string> sort_by_d(const libflo::node_list &flo)
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
