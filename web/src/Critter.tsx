import { useId } from 'react';
import { colors, defaultLook } from './model';
import type { Color, Look, Species } from './model';
export function Critter({ species = 'blob', color = 'grape', look, className = '' }: { species?: Species; color?: Color; look?: Look; className?: string }) {
  const id = useId().replace(/:/g, '');
  const s = look?.species ?? species, c = look?.color ?? color;
  const [ , fill, light] = colors[c];
  const l = { ...defaultLook, accessory: 'none', eyes: 'dots', ...look };
  const star = '100,27 120,68 166,75 133,108 141,155 100,133 59,155 67,108 34,75 80,68';
  return <svg className={`critter ${className}`} viewBox="0 0 200 190" aria-hidden="true" xmlns="http://www.w3.org/2000/svg">
    <defs><linearGradient id={id} x1="0" y1="0" x2="0.8" y2="1"><stop stopColor={light}/><stop offset="1" stopColor={fill}/></linearGradient></defs>
    <ellipse cx="100" cy="167" rx="56" ry="8" fill="#392452" opacity=".09"/>
    <g stroke={fill} strokeWidth="3" strokeLinejoin="round">
      {s === 'bunny' && <g fill={`url(#${id})`}><ellipse cx="73" cy="51" rx="17" ry="40" transform="rotate(-12 73 51)"/><ellipse cx="124" cy="48" rx="17" ry="40" transform="rotate(12 124 48)"/><path d="M70 29l7 37m49-40-7 39" stroke="#fff" strokeWidth="9" opacity=".6"/></g>}
      {s === 'bear' && <g fill={fill}><circle cx="57" cy="61" r="24"/><circle cx="143" cy="61" r="24"/></g>}
      {s === 'cat' && <path d="M45 89 46 34 85 63 119 63 154 34 156 90" fill={`url(#${id})`}/>}
      {s === 'frog' && <path d="M38 112c-2-23 4-37 15-47-2-21 7-36 23-36 13 0 22 8 24 22 3-14 12-22 24-22 16 0 25 15 23 36 11 10 17 24 15 47-2 34-23 50-62 50s-60-16-62-50Z" fill={`url(#${id})`}/>}
      {s === 'axolotl' && <g stroke="#e882a7" strokeWidth="11" strokeLinecap="round"><path d="M48 88 25 65m20 39-27-2m30 18-22 19m125-51 24-23m-20 39 27-2m-30 18 22 19"/></g>}
      {s === 'star' ? <polygon points={star} fill={`url(#${id})`}/> : s === 'popIt' ? <rect x="39" y="39" width="122" height="122" rx="32" fill="#dfc8f0"/> : s === 'cube' ? <><path d="m45 64 54-28 55 28-55 29Z" fill={light}/><path d="m45 64 54 29v67l-54-28Z" fill={fill}/><path d="m99 93 55-29v68l-55 28Z" fill="#a183d6"/></> : s === 'spinner' ? <path d="M82 86C50 20 141 13 119 83c70-7 54 80-3 40-41 62-95-8-34-37Z" fill={`url(#${id})`}/> : s !== 'frog' && <path d="M39 112C34 66 60 53 99 54c40-2 65 21 64 61-1 35-23 47-64 47-42 0-61-14-60-50Z" fill={`url(#${id})`}/>}
    </g>
    {s === 'popIt' ? <g>{Array.from({ length: 16 }, (_, i) => <g key={i}><circle cx={57 + i % 4 * 29} cy={58 + Math.floor(i / 4) * 29} r="11" fill={['#f3a9be','#f4ce75','#9bd1b5','#9dbce5'][Math.floor(i/4)]}/><path d={`M${51+i%4*29} ${57+Math.floor(i/4)*29}a7 7 0 0 1 10-5`} stroke="#fff" strokeWidth="2" opacity=".65" fill="none"/></g>)}</g> : s === 'cube' ? <g fill="#654799"><circle cx="65" cy="101" r="6"/><circle cx="82" cy="127" r="6"/><ellipse cx="127" cy="114" rx="14" ry="18" fill="#cbb6ed"/></g> : s === 'spinner' ? <g fill={light} stroke="#7e68a1" strokeWidth="3"><circle cx="99" cy="58" r="13"/><circle cx="140" cy="117" r="13"/><circle cx="65" cy="131" r="13"/><circle cx="99" cy="103" r="18"/></g> : <g fill="#44304f" stroke="#44304f" strokeWidth="3.5" strokeLinecap="round">
      {s === 'frog' && <g fill="#fffdfa" stroke="none"><ellipse cx="77" cy="55" rx="14" ry="17"/><ellipse cx="123" cy="55" rx="14" ry="17"/></g>}
      <g transform={s === 'frog' ? 'translate(0 -45)' : undefined}>
        {l.eyes === 'happy' || l.eyes === 'sleepy' ? <path d={l.eyes === 'happy' ? 'M70 102q7-11 14 0m32 0q7-11 14 0' : 'M70 101q7 6 14 0m32 0q7 6 14 0'} fill="none"/> : <><ellipse cx="77" cy="100" rx={l.eyes === 'sparkle' ? 6 : 4} ry="7"/>{l.eyes === 'wink' ? <path d="m117 98 10 5-10 3" fill="none"/> : <ellipse cx="123" cy="100" rx={l.eyes === 'sparkle' ? 6 : 4} ry="7"/>}{l.eyes === 'sparkle' && <g fill="white" stroke="none"><circle cx="75" cy="97" r="2.5"/><circle cx="121" cy="97" r="2.5"/></g>}</>}
      </g>
      <path d={s === 'frog' ? 'M63 110q37 32 74 0' : 'M90 115q10 12 20 0'} fill="none"/>
      {l.cheeks && <g fill="#ec7d9f" opacity=".5" stroke="none"><ellipse cx="62" cy="114" rx="10" ry="6"/><ellipse cx="138" cy="114" rx="10" ry="6"/></g>}
      {s === 'cat' && <path d="m53 103-15-3m16 12-15 3m107-12 15-3m-15 12 15 3" strokeWidth="2"/>}
    </g>}
    {l.accessory === 'crown' && <path d="m76 51-5-27 19 12 11-20 12 20 18-12-5 27Z" fill="#f5d269" stroke="#d8ae43" strokeWidth="2"/>}
    {l.accessory === 'bow' && <g fill="#e67a9f" stroke="#c55c85" strokeWidth="2"><path d="M123 58c-34-28-30 17 0 2 29 16 30-27 0-2Z"/><circle cx="123" cy="59" r="5"/></g>}
    {l.accessory === 'partyHat' && <><path d="m77 58 24-47 24 47Z" fill="#f4bf7b"/><path d="m85 42 30 2m-24-15 16 2" stroke="#f18db1" strokeWidth="6"/><circle cx="101" cy="12" r="7" fill="#c6a4e9"/></>}
    <path d="M54 84q4-12 14-13" fill="none" stroke="#fff" strokeWidth="5" opacity=".6" strokeLinecap="round"/>
    {s === 'otherSquishy' && <g transform="rotate(12 151 57)">
      <circle cx="151" cy="57" r="23" fill="#fff3c7" stroke="#d8ae43" strokeWidth="3"/>
      <path d="M143 50a8 8 0 1 1 13 6c-3 2-5 3-5 7" fill="none" stroke="#735789" strokeWidth="4.5" strokeLinecap="round"/>
      <circle cx="151" cy="70" r="2.5" fill="#735789"/>
    </g>}
  </svg>;
}
