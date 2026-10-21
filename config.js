// 사이트 곳곳에 들어가는 값. 비어 있으면 '준비 중'으로 보인다.
window.SITE = {
  testflight: '',       // TestFlight 공개 링크 (예: https://testflight.apple.com/join/XXXXXXXX)
  feedbackEmail: 'musicremote.feedback@gmail.com',    // 피드백·문의 이메일
  kofi: '',             // Ko-fi 주소 (예: https://ko-fi.com/아이디)
  githubSponsors: '',   // GitHub Sponsors 주소
};

// data-fill="키" 요소에 값을 채운다
document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('[data-fill]').forEach((node) => {
    const value = (window.SITE || {})[node.dataset.fill];
    if (node.tagName === 'A') {
      if (value) {
        node.href = node.dataset.fill === 'feedbackEmail' ? `mailto:${value}` : value;
        if (node.dataset.label !== 'keep') node.textContent = node.dataset.fill === 'feedbackEmail' ? value : node.textContent;
      } else {
        node.removeAttribute('href');
        node.setAttribute('aria-disabled', 'true');
        node.textContent = node.dataset.empty || '준비 중';
      }
    } else {
      node.textContent = value || node.dataset.empty || '준비 중';
    }
  });
  document.querySelectorAll('[data-show-if]').forEach((node) => {
    const keys = node.dataset.showIf.split(' ');
    node.hidden = !keys.some((key) => (window.SITE || {})[key]);
  });
});
