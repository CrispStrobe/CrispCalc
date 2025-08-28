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
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            double result = eval_double(*expr);
            std::ostringstream oss;
            oss << result;
            std::string result_str = oss.str();
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
                if (container.empty()) return string_to_char_ptr("No solutions found");
                std::ostringstream oss;
                bool first = true;
                for (const auto& sol : container) {
                    if (!first) oss << ", ";
                    oss << eval_double(*sol);
                    first = false;
                }
                return string_to_char_ptr(oss.str());
            } else {
                return string_to_char_ptr(rcp_static_cast<const Basic>(solution_set)->__str__());
            }
        } catch (const std::exception& e) {
            return string_to_char_ptr("Solve error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* cas_factor(const char* input_expr) {
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            auto poly = from_basic<UIntPolyFlint>(expr);
            std::vector<std::pair<RCP<const UIntPolyFlint>, long>> poly_factors = factors(*poly);

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
            if (oss.str().empty()) return string_to_char_ptr(expr->__str__());
            return string_to_char_ptr(oss.str());
        } catch (const std::exception& e) {
            return string_to_char_ptr("Factor Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    char* cas_expand(const char* input_expr) {
        try {
            RCP<const Basic> expr = parse(std::string(input_expr));
            RCP<const Basic> expanded_expr = expand(expr);
            return string_to_char_ptr(expanded_expr->__str__());
        } catch (const std::exception& e) {
            return string_to_char_ptr("Expand Error");
        }
    }

    __attribute__((visibility("default"))) __attribute__((used))
    void free_string(char* str) {
        if (str != nullptr) free(str);
    }
}