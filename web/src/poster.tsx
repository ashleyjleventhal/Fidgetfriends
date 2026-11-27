import { renderToStaticMarkup } from 'react-dom/server';
import { Critter } from './Critter';
import { colors, fitName, publicItems, shortName } from './model';
import type { Item } from './model';
export const perPage = 12;
export async function makePoster(items: Item[], page: number): Promise<Blob> {
  const safe = publicItems(items).slice(page * perPage, (page + 1) * perPage);
  const rows = Math.max(1, Math.ceil(safe.length / 3)), height = 310 + rows * 290;
  const xml = renderToStaticMarkup(<svg xmlns="http://www.w3.org/2000/svg" width="1080" height={height} viewBox={`0 0 1080 ${height}`}>
    <rect width="1080" height={height} rx="32" fill="#faf7f2"/>
    <text x="540" y="70" textAnchor="middle" fill="#7e5aa5" fontFamily="sans-serif" fontSize="20" letterSpacing="5">FIDGET FRIENDS</text>
    <text x="540" y="135" textAnchor="middle" fill="#35254f" fontFamily="sans-serif" fontSize="48" fontWeight="bold">My happy collection</text>
    <text x="540" y="182" textAnchor="middle" fill="#71627f" fontFamily="sans-serif" fontSize="22">A little squishy. A little fidgety. A whole lot of happy.</text>
    {safe.map((item, i) => <g key={i} transform={`translate(${48 + (i % 3) * 334}, ${220 + Math.floor(i / 3) * 290})`}>
      <rect width="316" height="270" rx="26" fill={colors[item.color][2]}/>
      <svg x="47" y="4" width="222" height="210" viewBox="0 0 200 190"><Critter species={item.species} color={item.color}/></svg>
      <text x="158" y="238" textAnchor="middle" fontFamily="sans-serif" fontWeight="bold" fill="#35254f" fontSize="24" {...fitName(shortName(item.name, 20))}>{shortName(item.name, 20)}</text>
    </g>)}
    <text x="540" y={height - 32} textAnchor="middle" fill="#71627f" fontFamily="sans-serif" fontSize="18">Made with Fidget Friends · {items.length} little joys{items.length > perPage ? ` · Page ${page + 1} of ${Math.ceil(items.length / perPage)}` : ''}</text>
  </svg>);
  const url = URL.createObjectURL(new Blob([xml], { type: 'image/svg+xml;charset=utf-8' }));
  try {
    const img = new Image(); img.src = url; await img.decode();
    const canvas = document.createElement('canvas'); canvas.width = 1080; canvas.height = height;
    const ctx = canvas.getContext('2d'); if (!ctx) throw new Error('Your browser cannot make a picture.');
    ctx.drawImage(img, 0, 0);
    return await new Promise<Blob>((resolve, reject) => canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('Picture could not be made.')), 'image/png'));
  } finally { URL.revokeObjectURL(url); }
}
