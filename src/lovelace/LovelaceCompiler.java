package lovelace;

import java.io.*;
import java.util.ArrayList;
import ast.*;

public class LovelaceCompiler {

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Uso: java lovelace.LovelaceCompiler <arquivo.lov>");
            System.exit(1);
        }

        String filename = args[0];

        try {
            StringBuilder content = new StringBuilder();
            BufferedReader reader = new BufferedReader(new FileReader(filename));
            String line;
            while ((line = reader.readLine()) != null) {
                content.append(line).append("\n");
            }
            reader.close();

            StringReader stringReader = new StringReader(content.toString());
            LovelaceParser parser = new LovelaceParser(stringReader);

            try {
                Prog arvore = parser.parse();
                System.out.println("Análise sintática concluída com sucesso!");
                geraCodigo(arvore, filename);
            } catch (ParseException e) {
                System.err.println("Erro de sintaxe na linha " + e.currentToken.beginLine +
                                 ", coluna " + e.currentToken.beginColumn + ": " + e.getMessage());
                System.exit(1);
            }

        } catch (FileNotFoundException e) {
            System.err.println("Erro: Arquivo não encontrado: " + filename);
            System.exit(1);
        } catch (IOException e) {
            System.err.println("Erro ao ler arquivo: " + e.getMessage());
            System.exit(1);
        } catch (TokenMgrError e) {
            System.err.println("Erro léxico: " + e.getMessage());
            System.exit(1);
        }
    }

    static void geraCodigo(Prog prog, String arquivo) {
        String outputFile = arquivo.replace(".lov", ".c");

        try {
            PrintWriter out = new PrintWriter(new FileWriter(outputFile));

            out.println("#include <stdio.h>");
            out.println();

            // Forward declarations for all functions
            for (Fun f : prog.fun) {
                out.print(mapType(f.retorno) + " " + f.nome + "(");
                for (int i = 0; i < f.params.size(); i++) {
                    if (i > 0) out.print(", ");
                    out.print(mapType(f.params.get(i).type) + " " + f.params.get(i).var);
                }
                out.println(");");
            }
            if (!prog.fun.isEmpty()) out.println();

            // Function definitions
            for (Fun f : prog.fun) {
                out.print(mapType(f.retorno) + " " + f.nome + "(");
                for (int i = 0; i < f.params.size(); i++) {
                    if (i > 0) out.print(", ");
                    out.print(mapType(f.params.get(i).type) + " " + f.params.get(i).var);
                }
                out.println(") {");

                for (VarDecl v : f.vars) {
                    out.println("    " + mapType(v.type) + " " + v.var + ";");
                }

                for (Comando c : f.body) {
                    geraComando(out, c, "    ");
                }

                out.println("}");
                out.println();
            }

            // Main function
            out.println("int main() {");

            for (VarDecl v : prog.main.vars) {
                out.println("    " + mapType(v.type) + " " + v.var + ";");
            }

            for (Comando c : prog.main.coms) {
                geraComando(out, c, "    ");
            }

            out.println("    return 0;");
            out.println("}");

            out.close();

            System.out.println("Código C gerado em: " + outputFile);

        } catch (IOException e) {
            System.err.println("Erro ao gerar código: " + e.getMessage());
            System.exit(1);
        }
    }

    static String mapType(String type) {
        switch (type) {
            case "Float": return "float";
            case "Bool": return "int";
            case "Void": return "void";
            default: return type;
        }
    }

    static void geraComando(PrintWriter out, Comando c, String indent) {
        if (c instanceof CAtribuicao) {
            CAtribuicao a = (CAtribuicao) c;
            out.println(indent + a.var + " = " + geraExp(a.exp) + ";");
        } else if (c instanceof CIf) {
            CIf ci = (CIf) c;
            out.println(indent + "if (" + geraExp(ci.exp) + ") {");
            for (Comando cmd : ci.bloco) {
                geraComando(out, cmd, indent + "    ");
            }
            out.println(indent + "}");
        } else if (c instanceof CWhile) {
            CWhile cw = (CWhile) c;
            out.println(indent + "while (" + geraExp(cw.exp) + ") {");
            for (Comando cmd : cw.bloco) {
                geraComando(out, cmd, indent + "    ");
            }
            out.println(indent + "}");
        } else if (c instanceof CPrint) {
            CPrint cp = (CPrint) c;
            String fmt = isBoolExp(cp.exp) ? "%d" : "%f";
            out.println(indent + "printf(\"" + fmt + "\\n\", " + geraExp(cp.exp) + ");");
        } else if (c instanceof CReadInput) {
            CReadInput cr = (CReadInput) c;
            out.println(indent + "scanf(\"%f\", &" + cr.var + ");");
        } else if (c instanceof CReturn) {
            CReturn cr = (CReturn) c;
            if (cr.exp != null) {
                out.println(indent + "return " + geraExp(cr.exp) + ";");
            } else {
                out.println(indent + "return;");
            }
        } else if (c instanceof CChamadaFun) {
            CChamadaFun cf = (CChamadaFun) c;
            StringBuilder sb = new StringBuilder();
            sb.append(cf.fun).append("(");
            for (int i = 0; i < cf.args.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(geraExp(cf.args.get(i)));
            }
            sb.append(")");
            out.println(indent + sb.toString() + ";");
        }
    }

    static String geraExp(Exp e) {
        if (e instanceof EFloat) {
            EFloat ef = (EFloat) e;
            return String.valueOf(ef.value);
        } else if (e instanceof EVar) {
            return ((EVar) e).var;
        } else if (e instanceof ETrue) {
            return "1";
        } else if (e instanceof EFalse) {
            return "0";
        } else if (e instanceof EOpExp) {
            EOpExp op = (EOpExp) e;
            return "(" + geraExp(op.arg1) + " " + op.op + " " + geraExp(op.arg2) + ")";
        } else if (e instanceof EChamadaFun) {
            EChamadaFun cf = (EChamadaFun) e;
            StringBuilder sb = new StringBuilder();
            sb.append(cf.fun).append("(");
            for (int i = 0; i < cf.args.size(); i++) {
                if (i > 0) sb.append(", ");
                sb.append(geraExp(cf.args.get(i)));
            }
            sb.append(")");
            return sb.toString();
        }
        return "";
    }

    static boolean isBoolExp(Exp e) {
        if (e instanceof ETrue || e instanceof EFalse) return true;
        if (e instanceof EOpExp) {
            String op = ((EOpExp) e).op;
            return op.equals("&&") || op.equals("||") ||
                   op.equals("<") || op.equals(">") || op.equals("==");
        }
        return false;
    }
}
