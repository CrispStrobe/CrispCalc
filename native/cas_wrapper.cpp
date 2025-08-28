#include <string>
#include <iostream>
#include <sstream>
#include <cstring>

#include <symengine/basic.h>
#include <symengine/symbol.h>
#include <symengine/parser.h>
#include <symengine/eval_double.h>
#include <symengine/solve.h>
#include <symengine/sets.h>

using namespace SymEngine;

// Helper to create a C-string for Dart.
char* string_to_char_ptr(const std::string& s) {
    return strdup(s.c_str());
}

extern "C" {
    __attribute__((visibility("default"))) __attribute__((used))
    char* evaluate(const char* input_expr) {
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            double result = eval_double(*expr);
            
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
            return string_to_char_ptr(result_str);
        } catch (const std::exception& e) {
            return string_to_char_ptr("Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* solve(const char* input_expr, const char* symbol_name) {
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            RCP<const Symbol> sym = symbol(std::string(symbol_name));
            RCP<const Set> solution_set = solve_poly(expr, sym);
            
            if (is_a<FiniteSet>(*solution_set)) {
                auto container = rcp_static_cast<const FiniteSet>(solution_set)->get_container();
                if (container.empty()) {
                    return string_to_char_ptr("No solutions found");
                }
                
                std::ostringstream oss;
                bool first = true;
                for (const auto& sol : container) {
                    if (!first) {
                        oss << ", ";
                    }
                    // --- FIX: Use the simple eval_double() to get a clean number ---
                    double numeric_solution = eval_double(*sol);
                    oss << numeric_solution;
                    first = false;
                }
                return string_to_char_ptr(oss.str());
            } else {
                std::ostringstream oss;
                oss << *solution_set;
                return string_to_char_ptr(oss.str());
            }
        } catch (const std::exception& e) {
            return string_to_char_ptr("Solve error");
        }
    }
    
    __attribute__((visibility("default"))) __attribute__((used))
    void free_string(char* str) {
        if (str != nullptr) {
            free(str);
        }
    }
}