package lovelace;

import java.io.*;

public class LovelaceSintatico {
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Uso: java lovelace.LovelaceSintatico <arquivo.lov>");
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
                parser.parse();
                System.out.println("Análise sintática concluída com sucesso!");
            } catch (ParseException e) {
                System.err.println("Erro de sintaxe na linha " + e.currentToken.beginLine + 
                                 ", coluna " + e.currentToken.beginColumn + ": " + e.getMessage());
                if (e.expectedTokenSequences != null && e.expectedTokenSequences.length > 0) {
                    System.err.println("Esperado: " + e.getMessage());
                }
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
}

