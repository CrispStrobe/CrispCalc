/// native/cas_wrapper.cpp

#include <string>
#include <iostream>
#include <sstream>
#include <cstring>
#include <vector>
#include <utility>

#include <symengine/basic.h>
#include <symengine/symbol.h>
#include <symengine/parser.h>
#include <symengine/eval_double.h>
#include <symengine/solve.h>
#include <symengine/sets.h>
#include <symengine/visitor.h>
#include <symengine/polys/uexprpoly.h>
#include <symengine/polys/basic_conversions.h>
#include <symengine/polys/uintpoly_flint.h>

using namespace SymEngine;

char* string_to_char_ptr(const std::string& s) {
    return strdup(s.c_str());
}

extern "C" {
    __attribute__((visibility("default"))) __attribute__((used))
    char* evaluate(const char* input_expr) {
        std::cout << "CPP EVAL: Input expression: '" << input_expr << "'" << std::endl;
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            std::cout << "CPP EVAL: Parsed successfully" << std::endl;
            double result = eval_double(*expr);
            std::cout << "CPP EVAL: Evaluated to: " << result << std::endl;
            std::ostringstream oss;
            oss << result;
            std::string result_str = oss.str();
            if (result_str.find('.') != std::string::npos) {
                result_str.erase(result_str.find_last_not_of('0') + 1, std::string::npos);
                if (!result_str.empty() && result_str.back() == '.') {
                    result_str.pop_back();
                }
            }
            std::cout << "CPP EVAL: Final result: '" << result_str << "'" << std::endl;
            return string_to_char_ptr(result_str);
        } catch (const std::exception& e) {
            std::cout << "CPP EVAL: Exception: " << e.what() << std::endl;
            return string_to_char_ptr("Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* solve(const char* input_expr, const char* symbol_name) {
        std::cout << "CPP SOLVE: Starting solve with expression: '" << input_expr 
                  << "', symbol: '" << symbol_name << "'" << std::endl;
        
        try {
            // Parse the expression
            std::cout << "CPP SOLVE: Parsing expression..." << std::endl;
            RCP<const Basic> expr = parse(std::string(input_expr));
            std::cout << "CPP SOLVE: Expression parsed successfully: " << expr->__str__() << std::endl;
            
            // Create symbol
            std::cout << "CPP SOLVE: Creating symbol..." << std::endl;
            RCP<const Symbol> sym = symbol(std::string(symbol_name));
            std::cout << "CPP SOLVE: Symbol created: " << sym->__str__() << std::endl;
            
            // Try to solve
            std::cout << "CPP SOLVE: Attempting to solve..." << std::endl;
            RCP<const Set> solution_set = solve_poly(expr, sym);
            std::cout << "CPP SOLVE: Solve completed, processing result set..." << std::endl;
            
            if (is_a<FiniteSet>(*solution_set)) {
                std::cout << "CPP SOLVE: Result is a finite set" << std::endl;
                auto container = rcp_static_cast<const FiniteSet>(solution_set)->get_container();
                std::cout << "CPP SOLVE: Container size: " << container.size() << std::endl;
                
                if (container.empty()) {
                    std::cout << "CPP SOLVE: No solutions found" << std::endl;
                    return string_to_char_ptr("No solutions found");
                }
                
                std::ostringstream oss;
                bool first = true;
                for (const auto& sol : container) {
                    std::cout << "CPP SOLVE: Processing solution: " << sol->__str__() << std::endl;
                    if (!first) oss << ", ";
                    try {
                        double val = eval_double(*sol);
                        std::cout << "CPP SOLVE: Solution evaluated to: " << val << std::endl;
                        oss << val;
                    } catch (const std::exception& eval_e) {
                        std::cout << "CPP SOLVE: Could not evaluate solution numerically: " << eval_e.what() << std::endl;
                        oss << sol->__str__();
                    }
                    first = false;
                }
                std::string result = oss.str();
                std::cout << "CPP SOLVE: Final result: '" << result << "'" << std::endl;
                return string_to_char_ptr(result);
            } else {
                std::cout << "CPP SOLVE: Result is not a finite set, returning string representation" << std::endl;
                std::string result = rcp_static_cast<const Basic>(solution_set)->__str__();
                std::cout << "CPP SOLVE: Result: '" << result << "'" << std::endl;
                return string_to_char_ptr(result);
            }
        } catch (const std::exception& e) {
            std::cout << "CPP SOLVE: Exception caught: " << e.what() << std::endl;
            return string_to_char_ptr("Solve error");
        } catch (...) {
            std::cout << "CPP SOLVE: Unknown exception caught" << std::endl;
            return string_to_char_ptr("Unknown solve error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* cas_factor(const char* input_expr) {
        std::cout << "CPP FACTOR: Input expression: '" << input_expr << "'" << std::endl;
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            std::cout << "CPP FACTOR: Expression parsed" << std::endl;
            auto poly = from_basic<UIntPolyFlint>(expr);
            std::cout << "CPP FACTOR: Converted to polynomial" << std::endl;
            std::vector<std::pair<RCP<const UIntPolyFlint>, long>> poly_factors = factors(*poly);
            std::cout << "CPP FACTOR: Factorization completed" << std::endl;

            std::ostringstream oss;
            bool first = true;
            for (const auto& pair : poly_factors) {
                if (!first) oss << " * ";
                std::string factor_str = pair.first->as_symbolic()->__str__();
                long exponent = pair.second;
                oss << "( " << factor_str << " )";
                if (exponent != 1) oss << "**" << exponent;
                first = false;
            }
            if (oss.str().empty()) {
                std::cout << "CPP FACTOR: No factors found, returning original" << std::endl;
                return string_to_char_ptr(expr->__str__());
            }
            std::cout << "CPP FACTOR: Result: '" << oss.str() << "'" << std::endl;
            return string_to_char_ptr(oss.str());
        } catch (const std::exception& e) {
            std::cout << "CPP FACTOR: Exception: " << e.what() << std::endl;
            return string_to_char_ptr("Factor Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* cas_expand(const char* input_expr) {
        std::cout << "CPP EXPAND: Input expression: '" << input_expr << "'" << std::endl;
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            std::cout << "CPP EXPAND: Expression parsed" << std::endl;
            RCP<const Basic> expanded_expr = expand(expr);
            std::cout << "CPP EXPAND: Expression expanded" << std::endl;
            std::string result = expanded_expr->__str__();
            std::cout << "CPP EXPAND: Result: '" << result << "'" << std::endl;
            return string_to_char_ptr(result);
        } catch (const std::exception& e) {
            std::cout << "CPP EXPAND: Exception: " << e.what() << std::endl;
            return string_to_char_ptr("Expand Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void free_string(char* str) {
        if (str != nullptr) {
            std::cout << "CPP: Freeing string: '" << str << "'" << std::endl;
            free(str);
        }
    }
}