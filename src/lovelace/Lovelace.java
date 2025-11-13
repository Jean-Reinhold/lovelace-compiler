package lovelace;

import java.io.*;
import java.util.HashMap;
import java.util.Map;

public class Lovelace {
    private static final Map<Integer, String> tokenNames = new HashMap<>();
    
    static {
        tokenNames.put(LovelaceParserConstants.MAIN, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.BEGIN, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.END, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.LET, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.FLOAT, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.BOOL, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.VOID, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.IF, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.WHILE, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.READ, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.RETURN, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.PRINT, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.DEF, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.TRUE, "Palavra reservada");
        tokenNames.put(LovelaceParserConstants.FALSE, "Palavra reservada");
        
        tokenNames.put(LovelaceParserConstants.ASSIGN, "Atribuição");
        tokenNames.put(LovelaceParserConstants.AND, "Operador lógico");
        tokenNames.put(LovelaceParserConstants.OR, "Operador lógico");
        tokenNames.put(LovelaceParserConstants.EQ, "Operador de comparação");
        tokenNames.put(LovelaceParserConstants.PLUS, "Operador aritmético");
        tokenNames.put(LovelaceParserConstants.MINUS, "Operador aritmético");
        tokenNames.put(LovelaceParserConstants.MULT, "Operador aritmético");
        tokenNames.put(LovelaceParserConstants.DIV, "Operador aritmético");
        tokenNames.put(LovelaceParserConstants.LT, "Operador de comparação");
        tokenNames.put(LovelaceParserConstants.GT, "Operador de comparação");
        
        tokenNames.put(LovelaceParserConstants.LPAREN, "Abre parênteses");
        tokenNames.put(LovelaceParserConstants.RPAREN, "Fecha parênteses");
        tokenNames.put(LovelaceParserConstants.SEMICOLON, "Ponto e virgula");
        tokenNames.put(LovelaceParserConstants.COMMA, "Vírgula");
        
        tokenNames.put(LovelaceParserConstants.IDENTIFIER, "Identificador");
        tokenNames.put(LovelaceParserConstants.NUMBER, "Número");
    }
    
    private static String getTokenDescription(Token token) {
        int kind = token.kind;
        String image = token.image;
        
        String baseName = tokenNames.get(kind);
        if (baseName == null) {
            return "Token desconhecido: " + image;
        }
        
        switch (kind) {
            case LovelaceParserConstants.LPAREN:
                return "Abre parênteses: (";
            case LovelaceParserConstants.RPAREN:
                return "Fecha parênteses: )";
            case LovelaceParserConstants.SEMICOLON:
                return "Ponto e virgula: ;";
            case LovelaceParserConstants.COMMA:
                return "Vírgula: ,";
            case LovelaceParserConstants.ASSIGN:
                return "Atribuição: :=";
            case LovelaceParserConstants.PLUS:
                return "Operador aritmético: +";
            case LovelaceParserConstants.MINUS:
                return "Operador aritmético: -";
            case LovelaceParserConstants.MULT:
                return "Operador aritmético: *";
            case LovelaceParserConstants.DIV:
                return "Operador aritmético: /";
            case LovelaceParserConstants.AND:
                return "Operador lógico: &&";
            case LovelaceParserConstants.OR:
                return "Operador lógico: ||";
            case LovelaceParserConstants.EQ:
                return "Operador de comparação: ==";
            case LovelaceParserConstants.LT:
                return "Operador de comparação: <";
            case LovelaceParserConstants.GT:
                return "Operador de comparação: >";
            case LovelaceParserConstants.IDENTIFIER:
                return "Identificador: " + image;
            case LovelaceParserConstants.NUMBER:
                return "Número: " + image;
            default:
                return baseName + ": " + image;
        }
    }
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Uso: java lovelace.Lovelace <arquivo.lov>");
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
            SimpleCharStream charStream = new SimpleCharStream(stringReader);
            LovelaceParserTokenManager tokenManager = new LovelaceParserTokenManager(charStream);
            
            Token token = tokenManager.getNextToken();
            while (token.kind != LovelaceParserConstants.EOF) {
                System.out.println(getTokenDescription(token));
                token = tokenManager.getNextToken();
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
}

