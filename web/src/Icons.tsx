export function Icon({ name, size = 22 }: { name: string; size?: number }) {
  const paths: Record<string, React.ReactNode> = {
    plus: <path d="M12 5v14M5 12h14"/>, close: <path d="m6 6 12 12M6 18 18 6"/>,
    heart: <path d="M20.8 4.6a5.5 5.5 0 0 0-7.8 0l-1 1-1-1a5.5 5.5 0 0 0-7.8 7.8L12 21l8.8-8.6a5.5 5.5 0 0 0 0-7.8Z"/>,
    search: <><circle cx="10.5" cy="10.5" r="6.5"/><path d="m16 16 5 5"/></>,
    shelf: <><rect x="3" y="4" width="18" height="16" rx="3"/><path d="M3 13h18M8 8v5m8-5v5M8 17h.01m8 0h.01"/></>,
    share: <><path d="M12 16V3m-4 4 4-4 4 4M5 12v8a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1v-8"/></>,
    sparkle: <><path d="m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5Z"/><path d="m21 2-1 3m-2-2 4 1"/></>,
    lock: <><rect x="5" y="10" width="14" height="11" rx="3"/><path d="M8 10V7a4 4 0 0 1 8 0v3m-4 5v2"/></>,
    check: <path d="m5 12 4 4L19 6"/>, info: <><circle cx="12" cy="12" r="9"/><path d="M12 11v6m0-10v.01"/></>,
    arrow: <path d="M4 12h16m-6-6 6 6-6 6"/>, download: <><path d="M12 3v12m-4-4 4 4 4-4M4 17v4h16v-4"/></>,
    cloud: <path d="M7 18a5 5 0 1 1 .7-10A6 6 0 0 1 19 10a4 4 0 1 1 0 8Z"/>,
    grid: <>{[4,14].flatMap(x => [4,14].map(y => <rect key={`${x}${y}`} x={x} y={y} width="6" height="6" rx="2"/>))}</>,
    edit: <><path d="m16 3 5 5-12 12-6 1 1-6Z"/><path d="m13 6 5 5"/></>,
  };
  return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">{paths[name] ?? paths.sparkle}</svg>;
}
