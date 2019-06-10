($ => {
  window.FILE_SIZE_LIMIT = 2 // 2mega
  $(() => {
    initEditor()
    initPhotoBtn()

    $(document)
      .on('click', '#photoBtn', () => {
        $('#photoInput').click()
      })
      .on('change', '#photoInput', ev => {
        const el = ev.currentTarget
        const file = el.files[0]
        if (file) {
          if (!judgeFile(file)) {
            el.value = ''
          }
        } else {
          $('#photoBtn').text('写真をアップ')
        }
      })

  document.addEventListener("dragenter", event => {
    event.preventDefault()
    event.stopPropagation()
    $('#photoBtn').text('ここにドロップしてください。')
  }, false)
  const photoBtn = document.getElementById('photoBtn')
  photoBtn.addEventListener('dragover', event => {
    event.preventDefault()
    event.stopPropagation()
    event.dataTransfer.dropEffect = 'copy'
    $('#photoBtn').addClass('-dragover')
  }, false)
  photoBtn.addEventListener('dragleave', event => {
    event.preventDefault()
    event.stopPropagation()
    $('#photoBtn').removeClass('-dragover')
  }, false)
  photoBtn.addEventListener('drop', event => {
    event.preventDefault()
    event.stopPropagation()
    event.dataTransfer.dropEffect = 'copy'
    let file = null
    if (event.dataTransfer) {
      file = event.dataTransfer.files[0]
    }
    console.log(file)
    // document.getElementById('photoInput').value = file
    // $('#photoInput').val(file)
    attachImage(file)
    $('#photoBtn').removeClass('-dragover')
  }, false)

  })
})(jQuery)

function initEditor() {
  const [dataYamlArea, styleTxtArea] = ['data_yml', 'style_txt'].map(id => {
    return document.getElementById(id)
  })
  if (!dataYamlArea || !styleTxtArea) {
    return
  }
  const editorOpt = {
    mode: "yaml",
    theme: 'eclipse',
    lineNumbers: true,
    indentUnit: 4
  }
  window.dataYamlEditor = CodeMirror.fromTextArea(dataYamlArea, editorOpt)
  window.styleTxtEditor = CodeMirror.fromTextArea(styleTxtArea, editorOpt)
  window.editorSave = () => {
    dataYamlEditor.save()
    styleTxtEditor.save()
    return true
  }
}

function initPhotoBtn() {
  const fileInput = document.querySelector('#photoInput')
  if (fileInput) {
    const file = fileInput.files[0]
    if (file) {
      setPhotoBtn(file)
    }
  }
}

function setPhotoBtn(file) {
  let fileName = file.name
  if (fileName.length > 10) {
    const l = fileName.length
    fileName = '...' + fileName.substring(l - 10, l)
  }
  $('#photoBtn').text(fileName)
}

function judgeFile(file) {
  if (file) {
    const fileSize = file.size
    const fileType = file.type
    if (!fileType.includes('image/')) {
      alert(`画像データを使ってください！`)
      $('#photoBtn').text('写真をアップ')
      return false
    } else if (fileSize > 1024 * 1024 * FILE_SIZE_LIMIT) {
      alert(`写真データを ${FILE_SIZE_LIMIT}m 以下にしてください！`)
      $('#photoBtn').text('写真をアップ')
      return false
    } else {
      setPhotoBtn(file)
      return true
    }
  } else {
    $('#photoBtn').text('写真をアップ')
    return false
  }
}

function attachImage(file) {
  var reader = new FileReader()
  reader.onload = function(event) {
    if (judgeFile(file)) {
      $('#photoInputBase64').val(event.target.result)
    } else {
      $('#photoInputBase64').val('')
    }
    $('#photoInput').val('')
  }
  reader.readAsDataURL(file)
}
