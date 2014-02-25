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
#include <map>
#include <queue>

node_list dataflow_order(const node_list &in)
{
    node_list out;
    std::queue<node_ptr> remaining;

    std::map<std::string, bool> scheduled;
    std::map<std::string, bool> schedable;

    /* Build the data structures used to perform this sort. */
    for (auto it = in.nodes(); !it.done(); ++it) {
        remaining.push(*it);

        schedable[(*it)->d()] = true;
    }

    /* Keep attempting to schedule nodes until there's none left in
     * the list of stuff to be scheduled. */
    size_t timer = 0;
    while (!remaining.empty()) {
        auto node = remaining.front();
        remaining.pop();
        bool work_done = false;

        switch (node->opcode()) {
            /* These nodes are always ready, all the time.  REG is a
             * special case: it actually doesn't do anything during
             * the dataflow schedule but instead gets a whole phase
             * dedicated to just storing its values later on. */
        case libflo::opcode::IN:
        case libflo::opcode::REG:
        case libflo::opcode::RND:
        case libflo::opcode::RST:
            out.add(node);
            scheduled[node->d()] = true;
            work_done = true;
            break;

            /* These nodes must wait for every one of their inputs to
             * be availiable before they can execute. */
        case libflo::opcode::ADD:
        case libflo::opcode::AND:
        case libflo::opcode::EQ:
        case libflo::opcode::GTE:
        case libflo::opcode::LT:
        case libflo::opcode::MOV:
        case libflo::opcode::MUX:
        case libflo::opcode::NOT:
        case libflo::opcode::OR:
        case libflo::opcode::OUT:
        case libflo::opcode::SUB:
        {
            bool all_ok = true;
            for (auto it = node->s_begin(); it != node->s_end(); ++it) {
                /* Check if the node has already been scheduled. */
                auto l = scheduled.find(*it);
                if (l == scheduled.end()) {
                    /* If the node hasn't been scheduled, then check
                     * if it's a schedulable node (as opposed to a
                     * constant, for example). */
                    auto m = schedable.find(*it);
                    if (m != schedable.end()) {
                        /* If it's schedulable but not yet scheduled
                         * then this node is missing one of its inputs
                         * and can't be scheduled until later. */
                        all_ok = false;
                    }
                }
            }

            if (all_ok == true) {
                out.add(node);
                scheduled[node->d()] = true;
                work_done = true;
            }
                

            break;
        }

            /* FIXME: Implement these opcodes once I know what to do
             * with them... */
        case libflo::opcode::EAT:
        case libflo::opcode::LIT:
        case libflo::opcode::CAT:
        case libflo::opcode::RSH:
        case libflo::opcode::MSK:
        case libflo::opcode::LD:
        case libflo::opcode::NEQ:
        case libflo::opcode::ARSH:
        case libflo::opcode::LSH:
        case libflo::opcode::XOR:
        case libflo::opcode::ST:
        case libflo::opcode::MEM:
        case libflo::opcode::NOP:
        case libflo::opcode::MUL:
        case libflo::opcode::LOG2:
        case libflo::opcode::NEG:
        case libflo::opcode::RD:
        case libflo::opcode::WR:
            fprintf(stderr, "Unable to order node type '%s'\n",
                    libflo::opcode_to_string(node->opcode()).c_str());
            abort();
            break;
        }

        /* If no work was done then add the node back onto the list of
         * nodes to be processed. */
        if (!work_done)
            remaining.push(node);
        else
            timer = 0;

        if (timer > remaining.size() * 2) {
            fprintf(stderr, "Unable to schedule all nodes, %lu remain:\n",
                    remaining.size());
            while (!remaining.empty()) {
                auto node = remaining.front();
                remaining.pop();
                fprintf(stderr, "  ");
                node->writeln(stderr);
            }
            abort();
        }
        timer++;
    }

    return out;
}
