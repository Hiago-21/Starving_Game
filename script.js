        function abrirTela(idTelaAlvo) {
            // Pega todas as telas e esconde elas
            const telas = document.querySelectorAll('.tela');
            telas.forEach(tela => {
                tela.classList.remove('ativa');
                tela.classList.add('escondida');
            });

            // Mostra apenas a tela que foi clicada
            const telaAlvo = document.getElementById(idTelaAlvo);
            telaAlvo.classList.remove('escondida');
            telaAlvo.classList.add('ativa');

            // Mostra ou Esconde o botão "Voltar"
            const btnVoltar = document.getElementById('btn-voltar');
            if (idTelaAlvo === 'tela-home') {
                btnVoltar.classList.add('escondido');
            } else {
                btnVoltar.classList.remove('escondido');
            }

            // Rola a página para o topo ao trocar de tela
            window.scrollTo(0, 0);
        }