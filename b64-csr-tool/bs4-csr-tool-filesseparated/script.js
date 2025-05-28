document.addEventListener('DOMContentLoaded', () => {
  const modeSelect = document.getElementById('mode');
  const textGroup = document.getElementById('textGroup');
  const userGroup = document.getElementById('userGroup');
  const passwordGroup = document.getElementById('passwordGroup');
  const convertBtn = document.getElementById('convertBtn');
  const inputText = document.getElementById('inputText');
  const usernameInput = document.getElementById('username');
  const passwordInput = document.getElementById('password');
  const resultGroup = document.getElementById('resultGroup');
  const resultText = document.getElementById('result');
  const copyMsg = document.getElementById('copyMsg');

  function encode(str) {
    const bytes = new TextEncoder().encode(str);
    let binary = '';
    bytes.forEach(b => binary += String.fromCharCode(b));
    return btoa(binary);
  }

  function decode(str) {
    const binary = atob(str);
    const bytes = new Uint8Array([...binary].map(ch => ch.charCodeAt(0)));
    return new TextDecoder().decode(bytes);
  }

  function decodeCSR(pem) {
    const csr = forge.pki.certificationRequestFromPem(pem);
    const attrs = csr.subject.attributes.map(a => `${a.shortName}=${a.value}`);
    return 'CSR Subject: ' + attrs.join(', ');
  }

  function decodeKey(pem) {
    const key = forge.pki.privateKeyFromPem(pem);
    return key.n && key.e ?
      `RSA Private Key - Modulus bits: ${key.n.bitLength()}, Exponent: ${key.e.toString()}` : 'Clave parseada';
  }

  function processInput() {
    let output;
    try {
      switch (modeSelect.value) {
        case 'encode': output = encode(inputText.value.trim()); break;
        case 'decode': output = decode(inputText.value.trim()); break;
        case 'csr':    output = decodeCSR(inputText.value.trim()); break;
        case 'key':    output = decodeKey(inputText.value.trim()); break;
        case 'userpass': output = encode(`${usernameInput.value}:${passwordInput.value}`); break;
      }
    } catch (e) {
      output = 'Error: ' + e.message;
    }
    resultText.value = output;
    resultGroup.style.display = 'block';
    copyMsg.style.display = 'none';
  }

  modeSelect.addEventListener('change', () => {
    resultGroup.style.display = 'none';
    copyMsg.style.display = 'none';
    if (modeSelect.value === 'userpass') {
      textGroup.style.display = 'none';
      userGroup.style.display = 'block';
      passwordGroup.style.display = 'block';
    } else {
      textGroup.style.display = 'block';
      userGroup.style.display = 'none';
      passwordGroup.style.display = 'none';
    }
  });

  convertBtn.addEventListener('click', processInput);
  [inputText, usernameInput, passwordInput].forEach(el =>
    el.addEventListener('keydown', e => {
      if (e.key === 'Enter') { e.preventDefault(); processInput(); }
    })
  );

  resultText.addEventListener('click', () => {
    if (!resultText.value) return;
    resultText.select();
    navigator.clipboard.writeText(resultText.value)
      .then(() => { copyMsg.style.display = 'block'; setTimeout(() => copyMsg.style.display = 'none', 2000); });
  });

  // CSR + ZIP generator
  document.getElementById('generateCsr').addEventListener('click', () => {
    const type = document.getElementById('csrType').value;
    const rawDns = document.getElementById('dns').value;
    if (rawDns !== rawDns.trim()) {
      alert('No puede haber espacios al inicio o final.');
      return;
    }
    const dns = rawDns.trim();
    if (!dns) { alert('Introduce la DNS para el Common Name.'); return; }

    let url;
    try {
      new URL(dns);
    } catch (_) {
      alert('Introduce una URL válida (incluye http:// o https://).');
      return;
    }

    const keypair = forge.pki.rsa.generateKeyPair({ bits: 2048, e: 0x10001 });
    const csr = forge.pki.createCertificationRequest();
    csr.publicKey = keypair.publicKey;
    csr.setSubject([
      { name: 'commonName', value: dns },
      { name: 'organizationalUnitName', value: 'Organizacion' },
      { name: 'organizationName', value: type === 'public' ? 'firmaPublica' : 'firmaInterna' },
      { name: 'localityName', value: 'Ciudad' },
      { name: 'stateOrProvinceName', value: 'Provincia' },
      { name: 'countryName', value: 'SP' },
      { name: 'emailAddress', value: 'mail@ejemplo.es' }
    ]);
    csr.setAttributes([{ name: 'extensionRequest', extensions: [{ name: 'subjectAltName', altNames: [{ type: 2, value: dns }] }] }]);
    csr.sign(keypair.privateKey, forge.md.sha256.create());

    const pemCsr = forge.pki.certificationRequestToPem(csr);
    const pemKey = forge.pki.privateKeyToPem(keypair.privateKey);

    const zip = new JSZip();
    zip.file(`${dns}.csr`, pemCsr);
    zip.file(`${dns}.key`, pemKey);
    zip.generateAsync({ type: 'blob' }).then(content => {
      const a = document.createElement('a');
      url = URL.createObjectURL(content);
      a.href = url;
      a.download = `${dns}.zip`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    });
  });
});
