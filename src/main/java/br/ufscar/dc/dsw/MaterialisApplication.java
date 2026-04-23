package br.ufscar.dc.dsw;

import java.io.IOException;
import java.io.InputStream;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.core.io.ClassPathResource;
import org.springframework.security.crypto.password.PasswordEncoder;

import br.ufscar.dc.dsw.dao.IEstudanteDAO;
import br.ufscar.dc.dsw.domain.Emprestimo;
import br.ufscar.dc.dsw.domain.Estudante;
import br.ufscar.dc.dsw.domain.Material;
import br.ufscar.dc.dsw.domain.Material.Categoria;
import br.ufscar.dc.dsw.domain.Material.EstadoConservacao;
import br.ufscar.dc.dsw.service.spec.IEmprestimoService;
import br.ufscar.dc.dsw.service.spec.IMaterialService;

@SpringBootApplication
public class MaterialisApplication {

    public static void main(String[] args) {
        SpringApplication.run(MaterialisApplication.class, args);
    }

    @Bean
    public CommandLineRunner demo(IEstudanteDAO estudanteDAO, IMaterialService materialService, 
                                  IEmprestimoService emprestimoService, PasswordEncoder passwordEncoder) {
        return (args) -> {
            
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd/MM/yyyy");

            // 0. CRIAÇÃO DO ADMIN
            if (estudanteDAO.findByEmail("admin@materialis.com") == null) {
                Estudante admin = new Estudante();
                admin.setEmail("admin@materialis.com");
                admin.setSenha(passwordEncoder.encode("admin")); 
                admin.setNome("Administrador");
                admin.setCpf("00000000000"); 
                admin.setTelefone("00000000000");
                admin.setSexo(Estudante.Sexo.Outro);
                admin.setNascimento(LocalDate.of(1990, 1, 1)); 
                admin.setRa("000000");
                admin.setRole("ROLE_ADMIN");
                estudanteDAO.save(admin);
                System.out.println("Usuário 'admin' criado com sucesso!");
            }

            // 1. CRIAÇÃO DOS ESTUDANTES
            if (estudanteDAO.findByEmail("lorena@gmail.com") == null) {
                Estudante e1 = new Estudante();
                e1.setCpf("12314192823");
                e1.setNome("Lorena");
                e1.setEmail("lorena@gmail.com");
                e1.setNascimento(LocalDate.parse("01/02/2000", formatter));
                e1.setRa("821239");
                e1.setSenha(passwordEncoder.encode("123abc"));
                e1.setSexo(Estudante.Sexo.Feminino);
                e1.setTelefone("16179238224");
                e1.setRole("ROLE_USER");
                estudanteDAO.save(e1);
            }

            if (estudanteDAO.findByEmail("luis@gmail.com") == null) {
                Estudante e2 = new Estudante();
                e2.setCpf("18228319201");
                e2.setNome("Luis");
                e2.setEmail("luis@gmail.com");
                e2.setNascimento(LocalDate.parse("05/10/1999", formatter));
                e2.setRa("123456");
                e2.setSenha(passwordEncoder.encode("password"));
                e2.setSexo(Estudante.Sexo.Masculino);
                e2.setTelefone("11987654321");
                e2.setRole("ROLE_USER");
                estudanteDAO.save(e2);
            }

            Estudante lorena = estudanteDAO.findByEmail("lorena@gmail.com");
            Estudante luis = estudanteDAO.findByEmail("luis@gmail.com");

            // 2. CRIAÇÃO DOS MATERIAIS
            // Materiais da Lorena
            if (lorena != null) {
                salvarMaterialComImagem(materialService, lorena, "Kit de Papelaria Completo", 
                    "Estojo completo para aulas.", Categoria.PAPELARIA, EstadoConservacao.NOVO, 
                    "Biblioteca Central", "static/images/kit_papelaria.jpeg", "image/jpeg");

                salvarMaterialComImagem(materialService, lorena, "Livro: Estruturas de Dados em Java", 
                    "Livro texto usado, 2ª edição. Cobre listas, pilhas, filas, árvores e grafos.", 
                    Categoria.LIVROS, EstadoConservacao.REGULAR, "Sala dos Projetos de IC, Prédio de Computação", 
                    "static/images/livro_java.jpg", "image/jpeg");

                salvarMaterialComImagem(materialService, lorena, "Calculadora Científica HP 50g", 
                    "Calculadora científica avançada, com funções de álgebra computacional.", 
                    Categoria.ELETRONICOS, EstadoConservacao.EXCELENTE, "Laboratório de Matemática, Prédio 5", 
                    "static/images/calculadora.jpg", "image/jpeg");
            }

            // Materiais do Luis
            if (luis != null) {
                salvarMaterialComImagem(materialService, luis, "Kit Arduino Uno", 
                    "Ideal para projetos de eletrônica.", Categoria.ELETRONICOS, EstadoConservacao.BOM, 
                    "Laboratório de Eletrônica", "static/images/kit_arduino.jpg", "image/jpeg");

                salvarMaterialComImagem(materialService, luis, "Livro: Banco de Dados Relacionais", 
                    "Livro em bom estado, aborda modelo relacional e SQL avançado.", 
                    Categoria.LIVROS, EstadoConservacao.BOM, "Sala de Aula de Banco de Dados, Bloco de TI", 
                    "static/images/livro_bd.jpg", "image/jpeg");
            }

            // 3. CRIAÇÃO DE EMPRÉSTIMO DE TESTE
            Material materialDeLuis = materialService.buscarPorDono(luis).stream()
                .filter(m -> m.getTitulo().equals("Kit Arduino Uno"))
                .findFirst().orElse(null);

            if (lorena != null && materialDeLuis != null) {
                boolean existeSolicitacao = emprestimoService.buscarPorEstudante(lorena).stream()
                        .anyMatch(e -> e.getMaterial().getId().equals(materialDeLuis.getId()));

                if (!existeSolicitacao) {
                    Emprestimo emprestimo = new Emprestimo();
                    emprestimo.setEstudante(lorena);
                    emprestimo.setMaterial(materialDeLuis);
                    emprestimo.setDataDevolucaoPrevista(LocalDate.now().plusDays(7));
                    emprestimo.setJustificativa("Uso acadêmico para projeto de Robótica.");
                    emprestimoService.salvar(emprestimo);
                }
            }
        };
    }

    /**
     * Método auxiliar para salvar materiais lendo a imagem do Classpath de forma segura para Docker/JAR
     */
    private void salvarMaterialComImagem(IMaterialService service, Estudante dono, String titulo, 
                                        String desc, Categoria cat, EstadoConservacao estado, 
                                        String local, String path, String contentType) {
        
        if (service.buscarPorDono(dono).stream().noneMatch(m -> m.getTitulo().equals(titulo))) {
            try {
                Material m = new Material();
                m.setTitulo(titulo);
                m.setDescricao(desc);
                m.setCategoria(cat);
                m.setEstadoConservacao(estado);
                m.setLocalRetirada(local);
                m.setEstudante(dono);

                // A MÁGICA PARA DOCKER ESTÁ AQUI:
                ClassPathResource res = new ClassPathResource(path);
                try (InputStream is = res.getInputStream()) {
                    byte[] imageBytes = is.readAllBytes();
                    m.setImagem(imageBytes);
                    m.setNomeImagem(path.substring(path.lastIndexOf("/") + 1));
                    m.setTipoImagem(contentType);
                }

                service.salvar(m);
            } catch (IOException e) {
                System.err.println("Erro ao carregar imagem " + path + ": " + e.getMessage());
            }
        }
    }
}