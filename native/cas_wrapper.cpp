#include <string>
#include <iostream>
#include <sstream>
#include <cstring>

// Use SymEngine C++ API instead of C API
#include <symengine/basic.h>
#include <symengine/symbol.h>
#include <symengine/parser.h>
#include <symengine/eval_double.h>
#include <symengine/solve.h>
#include <symengine/sets.h>

using namespace SymEngine;

extern "C" {

    __attribute__((visibility("default"))) __attribute__((used))
    char* evaluate(const char* input_expr) {
        try {
            // Parse the expression using C++ API
            RCP<const Basic> expr = parse(std::string(input_expr));
            
            // Convert to double value if possible
            double result = eval_double(*expr);
            
            // Convert result to string
            std::ostringstream oss;
            oss << result;
            std::string result_str = oss.str();
            
            // Clean up trailing zeros
            if (result_str.find('.') != std::string::npos) {
                result_str.erase(result_str.find_last_not_of('0') + 1, std::string::npos);
                if (!result_str.empty() && result_str.back() == '.') {
                    result_str.pop_back();
                }
            }
            
            return strdup(result_str.c_str());
        } catch (const std::exception& e) {
            return strdup("Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* solve(const char* input_expr, const char* symbol_name) {
        try {
            // Parse the expression
            RCP<const Basic> expr = parse(std::string(input_expr));
            
            // Create the symbol
            RCP<const Symbol> sym = symbol(std::string(symbol_name));
            
            // Try to solve - this returns RCP<const Set>
            RCP<const Set> solution_set = solve_poly(expr, sym);
            
            // Check if it's a FiniteSet and extract elements
            if (is_a<FiniteSet>(*solution_set)) {
                auto finite_set = rcp_static_cast<const FiniteSet>(solution_set);
                auto container = finite_set->get_container();
                
                if (container.empty()) {
                    return strdup("No solutions found");
                }
                
                // Format solutions as string
                std::ostringstream oss;
                bool first = true;
                for (const auto& sol : container) {
                    if (!first) {
                        oss << ", ";
                    }
                    oss << *sol;
                    first = false;
                }
                
                return strdup(oss.str().c_str());
            } else {
                // For other types of sets, just convert to string
                std::ostringstream oss;
                oss << *solution_set;
                return strdup(oss.str().c_str());
            }
        } catch (const std::exception& e) {
            return strdup("Solve error");
        }
    }
    
    __attribute__((visibility("default"))) __attribute__((used))
    void free_string(char* str) {
        if (str != nullptr) {
            free(str);
        }
    }
}