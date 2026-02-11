package lovelace;

import java.io.*;
import java.util.ArrayList;
import ast.*;

public class LovelaceASTDiagram {

    private static boolean dotMode = false;
    private static int nodeCounter = 0;

    public static void main(String[] args) {
        if (args.length < 1 || args.length > 2) {
            System.err.println("Uso: java lovelace.LovelaceASTDiagram <arquivo.lov> [--dot]");
            System.exit(1);
        }

        String filename = args[0];
        if (args.length == 2 && args[1].equals("--dot")) {
            dotMode = true;
        }

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
                System.err.println("Análise sintática concluída com sucesso!");
                if (dotMode) {
                    generateDot(arvore);
                } else {
                    generateText(arvore);
                }
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

    // =========================================================================
    // Text tree output
    // =========================================================================

    static void generateText(Prog prog) {
        System.out.println("Prog");
        int totalChildren = 1 + prog.fun.size();
        printTextMain(prog.main, "main", totalChildren <= 1);
        for (int i = 0; i < prog.fun.size(); i++) {
            boolean last = (i == prog.fun.size() - 1);
            printTextFun(prog.fun.get(i), "fun[" + i + "]", last);
        }
    }

    private static void printBranch(String prefix, boolean isLast, String edgeLabel, String text) {
        String connector = isLast ? "└── " : "├── ";
        String label = edgeLabel.isEmpty() ? "" : edgeLabel + ": ";
        System.out.println(prefix + connector + label + text);
    }

    private static String childPrefix(String prefix, boolean isLast) {
        return prefix + (isLast ? "    " : "│   ");
    }

    private static void printTextMain(Main main, String edge, boolean isLast) {
        String prefix = "";
        printBranch(prefix, isLast, edge, "Main");
        String cp = childPrefix(prefix, isLast);

        int total = main.vars.size() + main.coms.size();
        int idx = 0;
        for (int i = 0; i < main.vars.size(); i++) {
            boolean last = (++idx == total);
            printBranch(cp, last, "var[" + i + "]", main.vars.get(i).type + " " + main.vars.get(i).var);
        }
        for (int i = 0; i < main.coms.size(); i++) {
            boolean last = (++idx == total);
            printTextComando(main.coms.get(i), "cmd[" + i + "]", cp, last);
        }
    }

    private static void printTextFun(Fun fun, String edge, boolean isLast) {
        String prefix = "";
        printBranch(prefix, isLast, edge, "Fun: " + fun.nome + " (return: " + fun.retorno + ")");
        String cp = childPrefix(prefix, isLast);

        int total = fun.params.size() + fun.vars.size() + fun.body.size();
        int idx = 0;
        for (int i = 0; i < fun.params.size(); i++) {
            boolean last = (++idx == total);
            printBranch(cp, last, "param[" + i + "]", fun.params.get(i).type + " " + fun.params.get(i).var);
        }
        for (int i = 0; i < fun.vars.size(); i++) {
            boolean last = (++idx == total);
            printBranch(cp, last, "var[" + i + "]", fun.vars.get(i).type + " " + fun.vars.get(i).var);
        }
        for (int i = 0; i < fun.body.size(); i++) {
            boolean last = (++idx == total);
            printTextComando(fun.body.get(i), "cmd[" + i + "]", cp, last);
        }
    }

    private static void printTextComando(Comando c, String edge, String prefix, boolean isLast) {
        if (c instanceof CAtribuicao) {
            CAtribuicao a = (CAtribuicao) c;
            printBranch(prefix, isLast, edge, "Assign: " + a.var);
            String cp = childPrefix(prefix, isLast);
            printTextExp(a.exp, "value", cp, true);
        } else if (c instanceof CIf) {
            CIf ci = (CIf) c;
            printBranch(prefix, isLast, edge, "If");
            String cp = childPrefix(prefix, isLast);
            int total = 1 + ci.bloco.size();
            int idx = 0;
            printTextExp(ci.exp, "cond", cp, (++idx == total));
            for (int i = 0; i < ci.bloco.size(); i++) {
                boolean last = (++idx == total);
                printTextComando(ci.bloco.get(i), "body[" + i + "]", cp, last);
            }
        } else if (c instanceof CWhile) {
            CWhile cw = (CWhile) c;
            printBranch(prefix, isLast, edge, "While");
            String cp = childPrefix(prefix, isLast);
            int total = 1 + cw.bloco.size();
            int idx = 0;
            printTextExp(cw.exp, "cond", cp, (++idx == total));
            for (int i = 0; i < cw.bloco.size(); i++) {
                boolean last = (++idx == total);
                printTextComando(cw.bloco.get(i), "body[" + i + "]", cp, last);
            }
        } else if (c instanceof CPrint) {
            CPrint cp2 = (CPrint) c;
            printBranch(prefix, isLast, edge, "Print");
            String cp = childPrefix(prefix, isLast);
            printTextExp(cp2.exp, "value", cp, true);
        } else if (c instanceof CReadInput) {
            CReadInput cr = (CReadInput) c;
            printBranch(prefix, isLast, edge, "ReadInput: " + cr.var);
        } else if (c instanceof CReturn) {
            CReturn cr = (CReturn) c;
            if (cr.exp != null) {
                printBranch(prefix, isLast, edge, "Return");
                String cp = childPrefix(prefix, isLast);
                printTextExp(cr.exp, "value", cp, true);
            } else {
                printBranch(prefix, isLast, edge, "Return (void)");
            }
        } else if (c instanceof CChamadaFun) {
            CChamadaFun cf = (CChamadaFun) c;
            printBranch(prefix, isLast, edge, "Call: " + cf.fun);
            String cp = childPrefix(prefix, isLast);
            for (int i = 0; i < cf.args.size(); i++) {
                boolean last = (i == cf.args.size() - 1);
                printTextExp(cf.args.get(i), "arg[" + i + "]", cp, last);
            }
        }
    }

    private static void printTextExp(Exp e, String edge, String prefix, boolean isLast) {
        if (e instanceof EFloat) {
            printBranch(prefix, isLast, edge, String.valueOf(((EFloat) e).value));
        } else if (e instanceof EVar) {
            printBranch(prefix, isLast, edge, ((EVar) e).var);
        } else if (e instanceof ETrue) {
            printBranch(prefix, isLast, edge, "true");
        } else if (e instanceof EFalse) {
            printBranch(prefix, isLast, edge, "false");
        } else if (e instanceof EOpExp) {
            EOpExp op = (EOpExp) e;
            printBranch(prefix, isLast, edge, "(" + op.op + ")");
            String cp = childPrefix(prefix, isLast);
            printTextExp(op.arg1, "left", cp, false);
            printTextExp(op.arg2, "right", cp, true);
        } else if (e instanceof EChamadaFun) {
            EChamadaFun cf = (EChamadaFun) e;
            printBranch(prefix, isLast, edge, "Call: " + cf.fun);
            String cp = childPrefix(prefix, isLast);
            for (int i = 0; i < cf.args.size(); i++) {
                boolean last = (i == cf.args.size() - 1);
                printTextExp(cf.args.get(i), "arg[" + i + "]", cp, last);
            }
        }
    }

    // =========================================================================
    // DOT output
    // =========================================================================

    static void generateDot(Prog prog) {
        System.out.println("digraph AST {");
        System.out.println("    rankdir=TB;");
        System.out.println("    fontname=\"Helvetica\";");
        System.out.println("    node [fontname=\"Helvetica\", fontsize=11];");
        System.out.println("    edge [fontname=\"Helvetica\", fontsize=9];");
        System.out.println();

        visitProg(prog);

        System.out.println("}");
    }

    private static String newNode() {
        return "n" + (nodeCounter++);
    }

    private static String escape(String s) {
        return s.replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("<", "\\<")
                .replace(">", "\\>");
    }

    private static String visitProg(Prog prog) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Prog\", shape=doubleoctagon, "
                + "style=filled, fillcolor=\"#cce5ff\"];");

        String mainId = visitMain(prog.main);
        System.out.println("    " + id + " -> " + mainId + " [label=\"main\"];");

        for (int i = 0; i < prog.fun.size(); i++) {
            String funId = visitFun(prog.fun.get(i));
            System.out.println("    " + id + " -> " + funId + " [label=\"fun[" + i + "]\"];");
        }

        return id;
    }

    private static String visitMain(Main main) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Main\", shape=box, "
                + "style=filled, fillcolor=\"#fff3cd\"];");

        for (int i = 0; i < main.vars.size(); i++) {
            String varId = visitVarDecl(main.vars.get(i));
            System.out.println("    " + id + " -> " + varId + " [label=\"var[" + i + "]\"];");
        }

        for (int i = 0; i < main.coms.size(); i++) {
            String comId = visitComando(main.coms.get(i));
            System.out.println("    " + id + " -> " + comId + " [label=\"cmd[" + i + "]\"];");
        }

        return id;
    }

    private static String visitFun(Fun fun) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Fun: " + escape(fun.nome)
                + "\\nreturn: " + escape(fun.retorno) + "\", shape=box, "
                + "style=filled, fillcolor=\"#d4edda\"];");

        for (int i = 0; i < fun.params.size(); i++) {
            String paramId = visitParam(fun.params.get(i));
            System.out.println("    " + id + " -> " + paramId + " [label=\"param[" + i + "]\"];");
        }

        for (int i = 0; i < fun.vars.size(); i++) {
            String varId = visitVarDecl(fun.vars.get(i));
            System.out.println("    " + id + " -> " + varId + " [label=\"var[" + i + "]\"];");
        }

        for (int i = 0; i < fun.body.size(); i++) {
            String comId = visitComando(fun.body.get(i));
            System.out.println("    " + id + " -> " + comId + " [label=\"cmd[" + i + "]\"];");
        }

        return id;
    }

    private static String visitParam(ParamFormalFun param) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Param: " + escape(param.type)
                + " " + escape(param.var) + "\", shape=box, style=\"rounded,filled\", "
                + "fillcolor=\"#e2e3e5\"];");
        return id;
    }

    private static String visitVarDecl(VarDecl v) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"VarDecl: " + escape(v.type)
                + " " + escape(v.var) + "\", shape=box, style=\"rounded,filled\", "
                + "fillcolor=\"#e2e3e5\"];");
        return id;
    }

    private static String visitComando(Comando c) {
        if (c instanceof CAtribuicao) {
            return visitCAtribuicao((CAtribuicao) c);
        } else if (c instanceof CIf) {
            return visitCIf((CIf) c);
        } else if (c instanceof CWhile) {
            return visitCWhile((CWhile) c);
        } else if (c instanceof CPrint) {
            return visitCPrint((CPrint) c);
        } else if (c instanceof CReadInput) {
            return visitCReadInput((CReadInput) c);
        } else if (c instanceof CReturn) {
            return visitCReturn((CReturn) c);
        } else if (c instanceof CChamadaFun) {
            return visitCChamadaFun((CChamadaFun) c);
        }
        String id = newNode();
        System.out.println("    " + id + " [label=\"Comando?\", shape=box];");
        return id;
    }

    private static String visitCAtribuicao(CAtribuicao c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Assign: " + escape(c.var)
                + "\", shape=box, style=filled, fillcolor=\"#ffd6cc\"];");
        String expId = visitExp(c.exp);
        System.out.println("    " + id + " -> " + expId + " [label=\"value\"];");
        return id;
    }

    private static String visitCIf(CIf c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"If\", shape=diamond, "
                + "style=filled, fillcolor=\"#ffd6cc\"];");
        String condId = visitExp(c.exp);
        System.out.println("    " + id + " -> " + condId + " [label=\"cond\"];");
        for (int i = 0; i < c.bloco.size(); i++) {
            String comId = visitComando(c.bloco.get(i));
            System.out.println("    " + id + " -> " + comId + " [label=\"body[" + i + "]\"];");
        }
        return id;
    }

    private static String visitCWhile(CWhile c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"While\", shape=diamond, "
                + "style=filled, fillcolor=\"#ffd6cc\"];");
        String condId = visitExp(c.exp);
        System.out.println("    " + id + " -> " + condId + " [label=\"cond\"];");
        for (int i = 0; i < c.bloco.size(); i++) {
            String comId = visitComando(c.bloco.get(i));
            System.out.println("    " + id + " -> " + comId + " [label=\"body[" + i + "]\"];");
        }
        return id;
    }

    private static String visitCPrint(CPrint c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Print\", shape=box, "
                + "style=filled, fillcolor=\"#ffd6cc\"];");
        String expId = visitExp(c.exp);
        System.out.println("    " + id + " -> " + expId + " [label=\"value\"];");
        return id;
    }

    private static String visitCReadInput(CReadInput c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"ReadInput: " + escape(c.var)
                + "\", shape=box, style=filled, fillcolor=\"#ffd6cc\"];");
        return id;
    }

    private static String visitCReturn(CReturn c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Return\", shape=box, "
                + "style=filled, fillcolor=\"#ffd6cc\"];");
        if (c.exp != null) {
            String expId = visitExp(c.exp);
            System.out.println("    " + id + " -> " + expId + " [label=\"value\"];");
        }
        return id;
    }

    private static String visitCChamadaFun(CChamadaFun c) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Call: " + escape(c.fun)
                + "\", shape=box, style=filled, fillcolor=\"#ffd6cc\"];");
        for (int i = 0; i < c.args.size(); i++) {
            String argId = visitExp(c.args.get(i));
            System.out.println("    " + id + " -> " + argId + " [label=\"arg[" + i + "]\"];");
        }
        return id;
    }

    private static String visitExp(Exp e) {
        if (e instanceof EFloat) {
            return visitEFloat((EFloat) e);
        } else if (e instanceof EVar) {
            return visitEVar((EVar) e);
        } else if (e instanceof ETrue) {
            return visitETrue();
        } else if (e instanceof EFalse) {
            return visitEFalse();
        } else if (e instanceof EOpExp) {
            return visitEOpExp((EOpExp) e);
        } else if (e instanceof EChamadaFun) {
            return visitEChamadaFun((EChamadaFun) e);
        }
        String id = newNode();
        System.out.println("    " + id + " [label=\"Exp?\", shape=ellipse];");
        return id;
    }

    private static String visitEFloat(EFloat e) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"" + e.value
                + "\", shape=ellipse, style=filled, fillcolor=\"#f0f0f0\"];");
        return id;
    }

    private static String visitEVar(EVar e) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"" + escape(e.var)
                + "\", shape=ellipse, style=filled, fillcolor=\"#f0f0f0\"];");
        return id;
    }

    private static String visitETrue() {
        String id = newNode();
        System.out.println("    " + id + " [label=\"true\", shape=ellipse, "
                + "style=filled, fillcolor=\"#f0f0f0\"];");
        return id;
    }

    private static String visitEFalse() {
        String id = newNode();
        System.out.println("    " + id + " [label=\"false\", shape=ellipse, "
                + "style=filled, fillcolor=\"#f0f0f0\"];");
        return id;
    }

    private static String visitEOpExp(EOpExp e) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"" + escape(e.op)
                + "\", shape=circle, style=filled, fillcolor=\"#f0f0f0\"];");
        String leftId = visitExp(e.arg1);
        System.out.println("    " + id + " -> " + leftId + " [label=\"left\"];");
        String rightId = visitExp(e.arg2);
        System.out.println("    " + id + " -> " + rightId + " [label=\"right\"];");
        return id;
    }

    private static String visitEChamadaFun(EChamadaFun e) {
        String id = newNode();
        System.out.println("    " + id + " [label=\"Call: " + escape(e.fun)
                + "\", shape=ellipse, style=filled, fillcolor=\"#f0f0f0\"];");
        for (int i = 0; i < e.args.size(); i++) {
            String argId = visitExp(e.args.get(i));
            System.out.println("    " + id + " -> " + argId + " [label=\"arg[" + i + "]\"];");
        }
        return id;
    }
}
