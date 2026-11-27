import { renderToStaticMarkup } from 'react-dom/server';
import { Critter } from './Critter';
import { colors, publicItems } from './model';
import type { Item } from './model';
export const perPage = 12;
const tileWidth = 316;
const nameFont = 'sans-serif';
const segmenter = typeof Intl.Segmenter === 'function' ? new Intl.Segmenter() : null;

function fitName(ctx: CanvasRenderingContext2D, name: string) {
  const text = name.replace(/[ \t\r\n]+/g, ' ').trim();
  const characters = segmenter ? Array.from(segmenter.segment(text), part => part.segment) : Array.from(text);
  const fits = (line: string) => ctx.measureText(line).width <= tileWidth - 24;
  for (let fontSize = 24; ; fontSize--) {
    ctx.font = `bold ${fontSize}px ${nameFont}`;
    if (fits(text)) return { fontSize, lines: [text] };

    let end = 0;
    while (end < characters.length && fits(characters.slice(0, end + 1).join(''))) end++;
    const first = characters.slice(0, end).join('');
    const second = characters.slice(end).join('').trimStart();
    const space = first.lastIndexOf(' ');
    if (space > 0 && fits(text.slice(space + 1))) {
      return { fontSize, lines: [text.slice(0, space), text.slice(space + 1)] };
    }
    if (fits(second)) return { fontSize, lines: [first.trimEnd(), second] };

    if (fontSize === 15) {
      if (!end) return { fontSize, lines: ['…'] };
      let rest = characters.slice(end);
      while (rest.length && !fits(`${rest.join('').trim()}…`)) rest = rest.slice(0, -1);
      return { fontSize, lines: [first.trimEnd(), `${rest.join('').trim()}…`] };
    }
  }
}

export async function makePoster(items: Item[], page: number): Promise<Blob> {
  const safe = publicItems(items).slice(page * perPage, (page + 1) * perPage);
  const rows = Math.max(1, Math.ceil(safe.length / 3)), height = 310 + rows * 290;
  const canvas = document.createElement('canvas'); canvas.width = 1080; canvas.height = height;
  const ctx = canvas.getContext('2d'); if (!ctx) throw new Error('Your browser cannot make a picture.');
  const xml = renderToStaticMarkup(<svg xmlns="http://www.w3.org/2000/svg" width="1080" height={height} viewBox={`0 0 1080 ${height}`}>
    <rect width="1080" height={height} rx="32" fill="#faf7f2"/>
    <text x="540" y="70" textAnchor="middle" fill="#7e5aa5" fontFamily="sans-serif" fontSize="20" letterSpacing="5">FIDGET FRIENDS</text>
    <text x="540" y="135" textAnchor="middle" fill="#35254f" fontFamily="sans-serif" fontSize="48" fontWeight="bold">My happy collection</text>
    <text x="540" y="182" textAnchor="middle" fill="#71627f" fontFamily="sans-serif" fontSize="22">A little squishy. A little fidgety. A whole lot of happy.</text>
    {safe.map((item, i) => {
      const { fontSize, lines } = fitName(ctx, item.name);
      return <g key={i} transform={`translate(${48 + (i % 3) * 334}, ${220 + Math.floor(i / 3) * 290})`}>
        <rect width={tileWidth} height="270" rx="26" fill={colors[item.color][2]}/>
        <svg x="47" y="4" width="222" height="210" viewBox="0 0 200 190"><Critter species={item.species} color={item.color}/></svg>
        <text textAnchor="middle" fontFamily={nameFont} fontWeight="bold" fill="#35254f" fontSize={fontSize}>{lines.map((line, j) => <tspan key={j} x={tileWidth / 2} y={lines.length === 1 ? 238 : 233 + j * fontSize}>{line}</tspan>)}</text>
      </g>;
    })}
    <text x="540" y={height - 32} textAnchor="middle" fill="#71627f" fontFamily="sans-serif" fontSize="18">Made with Fidget Friends · {items.length} little joys{items.length > perPage ? ` · Page ${page + 1} of ${Math.ceil(items.length / perPage)}` : ''}</text>
  </svg>);
  const url = URL.createObjectURL(new Blob([xml], { type: 'image/svg+xml;charset=utf-8' }));
  try {
    const img = new Image(); img.src = url; await img.decode();
    ctx.drawImage(img, 0, 0);
    return await new Promise<Blob>((resolve, reject) => canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('Picture could not be made.')), 'image/png'));
  } finally { URL.revokeObjectURL(url); }
}
