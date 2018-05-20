﻿param ( [string]$job )

if (! $job) {
    Add-Type -AssemblyName System.Windows.Forms


    $Form = New-Object system.Windows.Forms.Form
    $listJobs = New-Object system.windows.Forms.ListView
    $btn = New-Object system.windows.Forms.Button
    $imageListIcons = New-Object System.Windows.Forms.ImageList
}

function getVersao {
    $version = "versao_indefinida"
    try {
        $hash = (git rev-parse HEAD) | Out-String
        $hash = $hash.substring(0,7)
        $commitCounter = (git rev-list --count master) | Out-String 
        $commitCounter = $commitCounter -replace "\s+" 
        $version = $commitCounter + "." + $hash 
        
    }catch{
        [System.Windows.Forms.MessageBox]::Show( "Git não instalado, não vai ser exibida a versão", "Erro" )
    }
    return $version
}

function limparNomeDaClasse {
    Param($classe)
    return $classe.ToString().ToLower().Replace(" ","-").Replace("í","i").Replace("ú","u").Replace("â","a").Replace("ã","a").Replace("á","a")
}

function gerarMacro {
    param ($classe)
    $eventMacros =  "eventMacros.txt"
    #Remover o arquivo antigo
    if (Test-Path $eventMacros) {
      Remove-Item $eventMacros
    }
    $versao = getVersao
    $jobSimples = limparNomeDaClasse($classe)
    $automacroVersao = Get-Content -Encoding UTF8 versao.pm 
    $automacroVersao = $automacroVersao -replace "<versao>",$versao
    $automacroVersao | Out-File $eventMacros -Encoding UTF8 -append 
    Get-Content -Encoding UTF8 classes\$jobSimples\*.pm | Out-File $eventMacros -Encoding UTF8 -append
    Get-Content -Encoding UTF8 comum\*.pm | Out-File $eventMacros -Encoding UTF8 -append
}

function acaoBotaoGerar {
    $classe = $listJobs.SelectedItems
    if ($classe.Count -eq 1) {
        gerarMacro($classe[0].Text)
        [System.Windows.Forms.MessageBox]::Show("eventMacros.txt para "+$classe[0].Text+" gerado com sucesso!" , "Ok")
        $Form.Dispose()
    } else{
        [System.Windows.Forms.MessageBox]::Show("Erro, nenhum item selecionado", "Selecione uma classe")
    }
}

function desenharJanela {
    $versao = getVersao
    $Form.Text = "Gerador eventMacros.txt versão: " + $versao
    $Form.TopMost = $true
    $Form.Width = 450
    $Form.Height = 400
    
    $listJobs.Width = 300
    $listJobs.Height = 300
    $listJobs.location = new-object system.drawing.point(10,20)
    $Form.controls.Add($listJobs)
    $listJobs.View = "LargeIcon"
    $listJobs.LargeImageList = $imageListIcons
    $listJobs.MultiSelect = false
    
    $btn.Text = "Gerar"
    $btn.Width = 60
    $btn.location = new-object system.drawing.point(310,20)
    $Form.controls.Add($btn)
    $Form.AcceptButton = $btn

    $btn.Add_click({ acaoBotaoGerar })
}

function carregarValores {
    
    $classes = "Cavaleiro Rúnico", "Guardião Real", "Arcano", "Feiticeiro", "Sentinela", "Trovador", "Musa", "Mecânico", "Bioquímico", "Sicário", "Renegado", "Arcebispo", "Shura", "Mestre Taekwon", "Espiritualista", "Kagerou", "Oboro", "Justiceiro", "Superaprendiz"

    For ($i=0; $i -lt $classes.Count; $i++) {
        $listItemClasse = New-Object System.Windows.Forms.ListViewItem
        $classe = limparNomeDaClasse($classes[$i])
        $imageListIcons.Images.Add([System.Drawing.Image]::FromFile("gerador-images/$classe.png"))
        $listItemClasse.ImageIndex = $i
        $listItemClasse.Text = $classes[$i]
        $listJobs.Items.Add($listItemClasse)
    } 
}

function mostrarJanela {
    [void]$Form.ShowDialog()
}

function encerrarAplicacao {
    $Form.Dispose()
}

function updater {
    if(getVersao -ne "versao_indefinida") {
        git fetch
        $versao_atual = (git rev-list --count origin/master) | Out-String
        $versao_local = (git rev-list --count master) | Out-String
        if($versao_atual -ne $versao_local) {
            $confirmacao = [System.Windows.Forms.MessageBox]::Show( "Nova versão disponível. Gostaria de atualizar sua versão?", "Versão desatualizada", [Windows.Forms.MessageBoxButtons]::YesNo )
            if ($confirmacao -eq "YES"){
                git stash save
                git pull --rebase
                git stash pop
            }
        }
    }
}

if(! $job){
    updater
    desenharJanela
    carregarValores
    mostrarJanela
    encerrarAplicacao
}else{
    gerarMacro($job)
}
