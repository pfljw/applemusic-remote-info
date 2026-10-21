// 사이트 곳곳에 들어가는 값. 비어 있으면 '준비 중'으로 보인다.
window.SITE = {
  testflight: '',       // TestFlight 공개 링크 (예: https://testflight.apple.com/join/XXXXXXXX)
  feedbackEmail: '',    // 피드백·문의 이메일
  toss: '',             // 토스 송금 링크 (예: https://toss.me/아이디)
  kakaopay: '',         // 카카오페이 송금 링크
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
    node.hidden = !(window.SITE || {})[node.dataset.showIf];
  });
});
