"""Acrescenta o alvo de teste de interface do vídeo (VideoGravarUITests) ao projeto da versão PUBLICADA, só pra compilação do simulador
no teste de atualização. Nenhum arquivo do app muda: entra um alvo de teste e um esquema novos. Uso: monta_uitest.py <pasta ios da anterior>"""
import os, shutil, sys
ios = sys.argv[1]
aqui = os.path.dirname(os.path.abspath(__file__))
os.makedirs(os.path.join(ios, 'ArquemestreVideoUITests'), exist_ok=True)
shutil.copy(os.path.join(aqui, 'VideoGravarUITests.swift'), os.path.join(ios, 'ArquemestreVideoUITests', 'VideoGravarUITests.swift'))
p = os.path.join(ios, 'project.yml'); s = open(p, encoding='utf-8').read()
alvo = '''  ArquemestreVideoUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - path: ArquemestreVideoUITests
    dependencies:
      - target: Arquemestre
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: br.com.arque.measure.videouitests
        GENERATE_INFOPLIST_FILE: YES
        TEST_TARGET_NAME: Arquemestre
'''
esquema = '''  ArquemestreVideoUI:
    build:
      targets:
        Arquemestre: all
        ArquemestreVideoUITests: [test]
    test:
      config: Debug
      targets:
        - ArquemestreVideoUITests
'''
assert '\nschemes:\n' in s and 'ArquemestreVideoUITests' not in s
s = s.replace('\nschemes:\n', '\n' + alvo + 'schemes:\n' + esquema, 1)
open(p, 'w', encoding='utf-8').write(s)
print('alvo ArquemestreVideoUITests e esquema ArquemestreVideoUI acrescentados em', p)
