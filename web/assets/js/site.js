$(function(){
  $('.reveal').each(function(){ $(this).addClass('js-ready'); });
  const reveal=new IntersectionObserver(function(entries){ entries.forEach(function(entry){ if(entry.isIntersecting){ $(entry.target).addClass('visible'); reveal.unobserve(entry.target); } }); },{threshold:.12});
  document.querySelectorAll('.reveal').forEach(function(el){ reveal.observe(el); });
  $(window).on('scroll',function(){
    const y=window.scrollY||0;
    $('.parallax').css('transform','translate3d(0,'+(y*.08)+'px,0)');
  });
});
