/// <reference types="vite/client" />
import React, { useEffect, useRef, useState } from 'react';
import { createRoot } from 'react-dom/client';
import '@fontsource/nunito/latin-400.css';
import '@fontsource/nunito/latin-600.css';
import '@fontsource/nunito/latin-700.css';
import '@fontsource/nunito/latin-800.css';
import '@fontsource/nunito/latin-900.css';
import './style.css';
import { Critter } from './Critter';
import { Icon } from './Icons';
import { buddySpecies, colors, defaultLook, emptyCollection, fidgetSpecies, filteredItems, isCollection, limitText, newItem, sampleItems, species, tags } from './model';
import type { Collection, Color, Filter, Item, Look, Profile, Species } from './model';
import { loadCollection, resizePhoto, saveCollection, StorageConflictError } from './storage';
import { makePoster, perPage } from './poster';

function Modal({ title, close, children, wide = false, editor = false }: { title: string; close?: () => void; children: React.ReactNode; wide?: boolean; editor?: boolean }) {
  const ref = useRef<HTMLDialogElement>(null);
  useEffect(() => { const previous = document.activeElement as HTMLElement | null; ref.current?.showModal(); document.body.style.overflow = 'hidden'; return () => { document.body.style.overflow = ''; (previous?.isConnected && previous !== document.body ? previous : document.getElementById('shelf'))?.focus(); }; }, []);
  return <dialog ref={ref} aria-label={title} className={`modal${wide ? ' wide' : ''}${editor ? ' editor-modal' : ''}`} onCancel={e => { e.preventDefault(); close?.(); }} onClick={e => { if (e.target === e.currentTarget) close?.(); }}>
    <div className="modal-head"><h2>{title}</h2>{close && <button className="icon-button" aria-label="Close" onClick={close}><Icon name="close"/></button>}</div>{children}
  </dialog>;
}
const setupDraftKey = 'fidget-friends-setup-draft';
function loadSetupDraft(): { profile: Profile; samples: boolean } | null {
  try { const draft = JSON.parse(sessionStorage.getItem(setupDraftKey) ?? 'null'); return draft && typeof draft.samples === 'boolean' && isCollection({ version: 1, profile: draft.profile, items: [] }) ? draft : null; } catch { return null; }
}
function saveSetupDraft(profile: Profile, samples: boolean) { try { sessionStorage.setItem(setupDraftKey, JSON.stringify({ profile, samples })); } catch { /* Storage may be full or blocked; setup still works without a draft. */ } }
function clearSetupDraft() { try { sessionStorage.removeItem(setupDraftKey); } catch { /* ignore */ } }
function ColorPicker({ value, onChange }: { value: Color; onChange: (c: Color) => void }) {
  return <div className="swatches">{(Object.keys(colors) as Color[]).map(c => <button key={c} type="button" className={`swatch ${value === c ? 'selected' : ''}`} style={{ background: c === 'rainbow' ? 'conic-gradient(#f5a9c6,#f5d76d,#8cd6b0,#94cbed,#b99ae9,#f5a9c6)' : colors[c][1] }} aria-label={colors[c][0]} aria-pressed={value === c} onClick={() => onChange(c)}>{value === c && <Icon name="check" size={19}/>}</button>)}</div>;
}
function ShapePicker({ choices, color, value, onChange }: { choices: Species[]; color: Color; value: Species; onChange: (shape: Species) => void }) {
  return <div className="species-picks">{choices.map(shape => <button key={shape} type="button" aria-pressed={value === shape} aria-label={species[shape]} className={value === shape ? 'selected' : ''} onClick={() => onChange(shape)}><Critter species={shape} color={color}/><span>{species[shape]}</span></button>)}</div>;
}
function StarterShelf({ filled }: { filled: boolean }) {
  return <svg viewBox="0 0 104 46" aria-hidden="true">
    <rect x="3" y="2" width="98" height="42" rx="6" fill="#f3edf9" stroke="#9974b9" strokeWidth="3"/>
    {filled && <>
      <path d="M12 21v-8l5 4 5-4v8Z" fill="#e59bbd"/>
      <rect x="28" y="10" width="13" height="11" rx="3" fill="#9bcdb3"/>
      <path d="m54 9 2.7 4 4.5 1.2-3 3.4.3 4.4-4.5-1.8-4.5 1.8.3-4.4-3-3.4 4.5-1.2Z" fill="#e9b844"/>
      <path d="M69 21v-5c0-4 4-6 9-6 6 0 9 3 9 6v5Z" fill="#ae91d6"/>
      <path d="m16 41 1-9 6-4 7 4 1 9Z" fill="#8abde0"/>
      <path d="M40 41v-3a7 7 0 0 1 3-6l-1-4c0-2 3-2 4 0l1 4h3l1-4c1-2 4-2 4 0l-1 4a7 7 0 0 1 3 6v3Z" fill="#d4a1de"/>
      <path d="M67 41v-4a8 8 0 0 1 8-8h5a8 8 0 0 1 8 8v4Z" fill="#f1ab83"/>
    </>}
    <path d="M4 22h96" stroke="#9974b9" strokeWidth="3"/>
  </svg>;
}
function BuddyEditor({ initial, onboarding = false, save, busy }: { initial?: Profile; onboarding?: boolean; save: (p: Profile, samples: boolean) => void; busy: boolean }) {
  const [draft] = useState(() => onboarding && !initial ? loadSetupDraft() : null);
  const [profile, setProfile] = useState<Profile>(initial ?? draft?.profile ?? { nickname: '', buddyName: 'Pip', look: defaultLook });
  const [samples, setSamples] = useState(draft?.samples ?? true);
  useEffect(() => { if (onboarding) saveSetupDraft(profile, samples); }, [onboarding, profile, samples]);
  const changeLook = (part: Partial<Look>) => setProfile(p => ({ ...p, look: { ...p.look, ...part } }));
  return <form onSubmit={e => { e.preventDefault(); save({ ...profile, nickname: profile.nickname.trim(), buddyName: profile.buddyName.trim() || 'Pip' }, samples); }} className="buddy-editor">
    <div className="editor-fields">
    <div className="buddy-preview"><span className="floating-star" aria-hidden="true">✦</span><Critter look={profile.look}/><span className="buddy-name">Hello, I’m {profile.buddyName.trim() || 'Pip'}!</span></div>
    <fieldset><legend>Pick your buddy</legend><ShapePicker choices={buddySpecies} color={profile.look.color} value={profile.look.species} onChange={species => changeLook({ species })}/></fieldset>
    <fieldset><legend>A favorite color</legend><ColorPicker value={profile.look.color} onChange={color => changeLook({ color })}/></fieldset>
    <div className="form-columns"><label>Eyes<select value={profile.look.eyes} onChange={e => changeLook({ eyes: e.target.value as Look['eyes'] })}>{['sparkle', 'dots', 'happy', 'sleepy', 'wink'].map(v => <option key={v} value={v}>{v[0].toUpperCase() + v.slice(1)}</option>)}</select></label><label>Little extra<select value={profile.look.accessory} onChange={e => changeLook({ accessory: e.target.value as Look['accessory'] })}><option value="none">Nothing extra</option><option value="crown">A tiny crown</option><option value="bow">A little bow</option><option value="partyHat">Party hat</option></select></label></div>
    <label className="check-label"><input type="checkbox" checked={profile.look.cheeks} onChange={e => changeLook({ cheeks: e.target.checked })}/> Rosy cheeks</label>
    <label>Buddy’s name <span className="optional">optional · keep Pip or choose a name</span><input value={profile.buddyName} onChange={e => setProfile({ ...profile, buddyName: limitText(e.target.value, 24, profile.buddyName) })}/></label>
    <label>Your nickname <span className="optional">optional · stays private</span><input value={profile.nickname} autoComplete="off" placeholder="What should your buddy call you?" onChange={e => setProfile({ ...profile, nickname: limitText(e.target.value, 24, profile.nickname) })}/></label>
    {onboarding && <p className="small center muted"><Icon name="lock" size={14}/> No accounts. No ads. Just your little world.</p>}
    </div>
    <div className="editor-actions">
      {onboarding && <div className="starter-choices" role="group" aria-label="Starter toys">
        {([true, false] as const).map(filled => <button type="button" key={String(filled)} aria-pressed={samples === filled} onClick={() => setSamples(filled)}>
          <StarterShelf filled={filled}/><span>{filled ? '7 pretend toys' : 'Empty shelf'}</span>
          {samples === filled && <span className="starter-selected"><Icon name="check" size={14}/></span>}
        </button>)}
      </div>}
      <button className="button primary full" disabled={busy}>{busy ? 'Saving…' : onboarding ? 'Meet my happy shelf' : 'Save my buddy'}<Icon name={onboarding ? 'arrow' : 'check'}/></button>
    </div>
  </form>;
}
function ItemEditor({ initial, save, busy }: { initial?: Item; save: (i: Item) => void; busy: boolean }) {
  const [item, setItem] = useState<Item>(initial ?? newItem());
  const [photoBusy, setPhotoBusy] = useState(false), [photoError, setPhotoError] = useState('');
  const choices: Species[] = item.kind === 'squishy' ? [...buddySpecies, 'otherSquishy'] : fidgetSpecies;
  return <form className="item-editor" onSubmit={e => { e.preventDefault(); save({ ...item, name: item.name.trim() || species[item.species], notes: item.notes.trim() }); }}>
    <div className="editor-fields">
    <div className="item-preview" style={{ background: colors[item.color][2] }}>{item.photo ? <img src={item.photo} alt="Your toy preview"/> : <Critter species={item.species} color={item.color}/>}</div>
    <fieldset><legend>Pick a toy</legend><div className="segmented">{(['squishy', 'fidget'] as const).map(kind => <button type="button" key={kind} aria-pressed={item.kind === kind} className={item.kind === kind ? 'selected' : ''} onClick={() => setItem(prev => prev.kind === kind ? prev : { ...prev, kind, species: kind === 'squishy' ? 'blob' : 'popIt' })}><Icon name={kind === 'squishy' ? 'cloud' : 'grid'}/>{kind === 'squishy' ? 'Squishy' : 'Fidget'}</button>)}</div></fieldset>
    <fieldset><legend>Shape</legend><ShapePicker choices={choices} color={item.color} value={item.species} onChange={species => setItem({ ...item, species })}/></fieldset>
    <fieldset><legend>Color</legend><ColorPicker value={item.color} onChange={color => setItem({ ...item, color })}/></fieldset>
    <label>Toy name <span className="optional">optional · we’ll use the shape’s name</span><input placeholder={species[item.species]} value={item.name} onChange={e => setItem({ ...item, name: limitText(e.target.value, 40, item.name) })}/></label>
    <fieldset><legend>How does it feel?</legend><div className="tag-picks">{tags.map(t => <button key={t} type="button" aria-pressed={item.tags.includes(t)} className={item.tags.includes(t) ? 'selected' : ''} onClick={() => setItem({ ...item, tags: item.tags.includes(t) ? item.tags.filter(v => v !== t) : [...item.tags, t] })}>{t}</button>)}</div></fieldset>
    <label className="check-label"><input type="checkbox" checked={item.favorite} onChange={e => setItem({ ...item, favorite: e.target.checked })}/> One of my favorites</label>
    <label>A photo <span className="optional">optional · stays on this device</span><input type="file" accept="image/*" disabled={photoBusy || busy} onChange={async e => { const file = e.target.files?.[0]; if (!file) return; setPhotoBusy(true); setPhotoError(''); try { const photo = await resizePhoto(file); setItem(p => ({ ...p, photo })); } catch (error) { setPhotoError((error as Error).message); } finally { setPhotoBusy(false); e.target.value = ''; } }}/></label>
    {photoBusy && <p role="status">Opening photo…</p>}{photoError && <p role="alert" className="error">{photoError}</p>}{item.photo && <button type="button" className="text-button" onClick={() => setItem({ ...item, photo: undefined })}>Remove photo</button>}
    <label>Private little notes <span className="optional">never included in sharing</span><textarea rows={3} value={item.notes} placeholder="A birthday gift? A super-satisfying squish?" onChange={e => setItem({ ...item, notes: limitText(e.target.value, 1000, item.notes) })}/></label>
    </div>
    <div className="editor-actions"><button className="button primary full" disabled={busy || photoBusy}>{busy ? 'Saving…' : initial ? 'Save changes' : 'Add to my shelf'}<Icon name={initial ? 'check' : 'plus'}/></button></div>
  </form>;
}
function canSharePicture(file: File) {
  try {
    return typeof navigator.share === 'function' && navigator.canShare?.({ files: [file] }) === true;
  } catch {
    return false;
  }
}
function ShareActions({ picture }: { picture: { file: File; url: string } }) {
  const [error, setError] = useState('');
  const canShare = canSharePicture(picture.file);
  async function share() {
    setError('');
    try {
      await navigator.share({ files: [picture.file], title: 'My happy collection' });
    } catch (e) {
      if ((e as Error).name !== 'AbortError') setError('Sharing is unavailable here. Use Save picture instead.');
    }
  }
  return <>{error && <p className="error" role="alert">{error}</p>}<div className="share-actions">
    {canShare && <button className="button primary full" onClick={share}><Icon name="share"/>Share picture</button>}
    <a className={`button ${canShare ? 'secondary' : 'primary'} full`} href={picture.url} download={picture.file.name}><Icon name="download"/>Save picture</a>
    <p className="small muted">On iPad or iPhone, you can also touch and hold the picture, then choose Save to Photos.</p>
  </div></>;
}
type ShareAttempts = { wrong: number; lockedUntil: number };
const noShareAttempts: ShareAttempts = { wrong: 0, lockedUntil: 0 };
const shareCooldown = 30_000;
function nextShareQuestion(previousProduct?: number) {
  const a = 3 + Math.floor(Math.random() * 7), b = 3 + Math.floor(Math.random() * 7);
  return [a * b === previousProduct ? (a === 9 ? 3 : a + 1) : a, b];
}
function ShareGate({ attempts, setAttempts, pass }: { attempts: ShareAttempts; setAttempts: (value: ShareAttempts) => void; pass: () => void }) {
  const [answer, setAnswer] = useState(''), [wrong, setWrong] = useState(false);
  const [question, setQuestion] = useState(() => nextShareQuestion());
  const locked = attempts.lockedUntil > Date.now();
  useEffect(() => {
    if (!attempts.lockedUntil) return;
    const timer = window.setTimeout(() => setAttempts(noShareAttempts), Math.max(0, attempts.lockedUntil - Date.now()));
    return () => window.clearTimeout(timer);
  }, [attempts.lockedUntil, setAttempts]);
  function submit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const now = Date.now();
    if (attempts.lockedUntil > now || !answer.trim()) return;
    const product = question[0] * question[1];
    if (Number(answer) === product) {
      setAttempts(noShareAttempts);
      pass();
      return;
    }
    const misses = (attempts.lockedUntil ? 0 : attempts.wrong) + 1;
    setAttempts({ wrong: misses, lockedUntil: misses === 3 ? now + shareCooldown : 0 });
    setWrong(misses < 3);
    setAnswer('');
    setQuestion(nextShareQuestion(product));
  }
  return <div className="gate"><div className="gate-icon"><Icon name="lock" size={34}/></div><h3>A little help from a grown-up</h3><p>Ask a grown-up before making a picture to share outside Fidget Friends.</p><p className="small muted">Toy names and drawings appear in the picture. Nickname, notes, and photos stay private. Please check toy names for personal information.</p>
    <form onSubmit={submit}>
      <label>Grown-ups: what is {question[0]} × {question[1]}?<input type="text" inputMode="numeric" pattern="[0-9]*" maxLength={3} value={answer} onChange={e => setAnswer(e.target.value)} autoComplete="off" disabled={locked}/></label>
      {locked ? <p role="status">Let’s take a little pause. Grown-ups, please wait 30 seconds before trying again.</p> : wrong && <p className="error" role="alert">Not quite. Ask a grown-up to try this new question.</p>}
      <button className="button primary full" disabled={locked}>Make collection picture<Icon name="sparkle"/></button>
    </form>
  </div>;
}
function ShareCollection({ items, attempts, setAttempts }: { items: Item[]; attempts: ShareAttempts; setAttempts: (value: ShareAttempts) => void }) {
  const [passed, setPassed] = useState(false);
  const [page, setPage] = useState(0), [picture, setPicture] = useState<{ file: File; url: string } | null>(null), [error, setError] = useState('');
  useEffect(() => {
    if (!passed) return;
    let active = true, url = ''; setPicture(null); setError('');
    makePoster(items, page).then(blob => {
      if (!active) return;
      const file = new File([blob], `fidget-friends-${page + 1}.png`, { type: 'image/png' });
      url = URL.createObjectURL(file); setPicture({ file, url });
    }).catch(() => { if (active) setError('The picture could not be made. Close this and try again.'); });
    return () => { active = false; if (url) URL.revokeObjectURL(url); };
  }, [passed, items, page]);
  if (!passed) return <ShareGate attempts={attempts} setAttempts={setAttempts} pass={() => setPassed(true)}/>;
  const pages = Math.ceil(items.length / perPage);
  return <div className="share-preview"><p className="muted">Just the toy names and drawings. No nickname, notes, or photos. Scroll the picture to check every toy name.</p>{error && <p className="error" role="alert">{error}</p>}
    {picture ? <div key={page} className="share-poster" role="region" aria-label="Scrollable collection picture" tabIndex={0}><img src={picture.url} alt={`Collection picture, page ${page + 1} of ${pages}`}/></div> : !error && <p role="status">Making a little shelf magic…</p>}{pages > 1 && <div className="pager"><button className="button secondary" disabled={page === 0} onClick={() => setPage(page - 1)}>Previous</button><span>Page {page + 1} of {pages}</span><button className="button secondary" disabled={page === pages-1} onClick={() => setPage(page + 1)}>Next</button></div>}{picture && <ShareActions key={picture.url} picture={picture}/>}</div>;
}
function App() {
  const [data, setData] = useState<Collection>(emptyCollection), [loading, setLoading] = useState(true), [loadError, setLoadError] = useState('');
  const [busy, setBusy] = useState(false), [error, setError] = useState(''), [toast, setToast] = useState('');
  const [filter, setFilter] = useState<Filter>('all'), [query, setQuery] = useState('');
  const [modal, setModal] = useState<'onboard' | 'buddy' | 'add' | 'edit' | 'detail' | 'share' | 'info' | 'delete' | null>(null), [selected, setSelected] = useState<Item | null>(null);
  const [addedItemId, setAddedItemId] = useState<string | null>(null);
  const [shareAttempts, setShareAttempts] = useState(noShareAttempts);
  const saveLock = useRef(false);
  useEffect(() => { loadCollection().then(c => { setData(c); if (!c.profile) setModal('onboard'); }).catch(() => setLoadError('We couldn’t open storage on this device. Your saved data has not been changed. Close other tabs, leave Private Browsing, then reload to try again.')).finally(() => setLoading(false)); }, []);
  useEffect(() => { if (!toast) return; const timer = setTimeout(() => setToast(''), 3200); return () => clearTimeout(timer); }, [toast]);
  useEffect(() => {
    if (modal || !addedItemId) return;
    const toy = document.getElementById(`toy-${addedItemId}`);
    toy?.scrollIntoView({ block: 'center' });
    toy?.focus({ preventScroll: true });
    setAddedItemId(null);
  }, [modal, addedItemId]);
  async function commit(next: Collection, message: string, close = true) {
    if (saveLock.current) return false; saveLock.current = true; setBusy(true); setError('');
    try { await saveCollection(next, data); setData(next); setToast(message); if (close) setModal(null); return true; } catch (error) { setError(error instanceof StorageConflictError ? error.message : 'Your change wasn’t saved. This device may be out of space. Keep this window open and try again after freeing some space.'); return false; } finally { setBusy(false); saveLock.current = false; }
  }
  async function saveItem(item: Item) {
    if (modal === 'edit') {
      await commit({ ...data, items: data.items.map(i => i.id === item.id ? item : i) }, 'Little makeover saved!');
    } else if (await commit({ ...data, items: [...data.items, item] }, 'A new friend on your shelf!')) {
      if (!filteredItems([item], filter, query).length) { setFilter('all'); setQuery(''); }
      setAddedItemId(item.id);
    }
  }
  function close() { if (busy) return; if ((modal === 'edit' || modal === 'add' || modal === 'buddy') && !window.confirm('Leave without saving your changes?')) return; setModal(null); setError(''); }
  const profile = data.profile ?? { nickname: '', buddyName: 'Pip', look: defaultLook };
  const visible = filteredItems(data.items, filter, query);
  const counts = { squishy: data.items.filter(i => i.kind === 'squishy').length, fidget: data.items.filter(i => i.kind === 'fidget').length, favorite: data.items.filter(i => i.favorite).length };
  if (loadError) return <main className="loading"><Critter/><h1>Your shelf is safe</h1><p role="alert">{loadError}</p><button className="button primary" onClick={() => location.reload()}>Try again</button></main>;
  if (loading) return <main className="loading"><Critter/><h1>Waking up your little friends…</h1></main>;
  return <><aside className="sidebar"><a href="#shelf" className="brand"><span className="brand-mark"><Critter color="grape"/></span><span>fidget<span>friends<span className="brand-dot">.</span></span></span></a><p className="sidebar-label">YOUR LITTLE WORLD</p><nav aria-label="Main"><button className="nav-link active" onClick={() => { setFilter('all'); setQuery(''); document.getElementById('shelf')?.focus(); }}><Icon name="shelf"/>My happy shelf<span className="nav-count">{data.items.length}</span></button><button className="nav-link" onClick={() => setModal('buddy')}><Icon name="sparkle"/>My buddy</button><button className="nav-link" disabled={!data.items.length} onClick={() => setModal('share')}><Icon name="share"/>Share collection</button></nav><div className="sidebar-buddy"><span className="tiny-spark" aria-hidden="true">✦</span><Critter look={profile.look}/><p>{profile.buddyName} says…</p><strong>“Little things.<br/>Big happy feelings.”</strong><button className="text-button" onClick={() => setModal('buddy')}>Make me your own <Icon name="arrow" size={15}/></button></div><button className="local-note" onClick={() => setModal('info')}><Icon name="lock" size={17}/><span>Just yours. On this device.<small>No accounts, no worries.</small></span><Icon name="info" size={16}/></button></aside>
    <main className="main" id="shelf" tabIndex={-1}><header className="topbar"><span className="topbar-label"><span className="status-dot"/> A little space for your favorite things</span><button className="profile-button" onClick={() => setModal('buddy')}><span className="sr-only">Edit my buddy: </span><span className="avatar"><Critter look={profile.look}/></span><span>{profile.nickname || 'Hello, friend'}<small>You + {profile.buddyName}</small></span><span className="down-caret" aria-hidden="true">⌄</span></button></header>
    <div className="page-content"><div className="page-heading"><div><p className="eyebrow">COLLECT LITTLE JOYS</p><h1>My happy shelf<span className="heading-star" aria-hidden="true">✦</span></h1><p>A happy little home for all your squishies & fidgets.</p></div><button className="button primary add-top" onClick={() => setModal('add')}><Icon name="plus"/>Add a little friend</button></div>
    <section className="welcome-banner" aria-label="Welcome"><div className="banner-copy"><span className="pill"><span/> YOUR COLLECTION, YOUR WAY</span><h2>A little squishy.<br/>A little fidgety.<br/><em>A whole lot of happy.</em></h2><p>Big collections or one special favorite.<br/>There’s room for every little joy here.</p><button className="banner-link" onClick={() => setModal('buddy')}>Meet your collection buddy <Icon name="arrow" size={18}/></button></div><div className="banner-art" aria-hidden="true"><span className="art-spark s1">✦</span><span className="art-spark s2">✧</span><span className="art-spark s3">✦</span><span className="art-dot d1"/><span className="art-dot d2"/><div className="art-circle"/><Critter className="banner-frog" species="frog" color="mint"/><Critter className="banner-buddy" look={profile.look}/><Critter className="banner-star" species="star" color="sunshine"/><span className="hello-sticker">hi, friend!<span>♡</span></span></div></section>
    <div className="stats" aria-label="Collection counts"><div><span className="stat-icon purple"><Icon name="shelf"/></span><strong>{data.items.length}</strong><span>little friends</span></div><div><span className="stat-icon pink"><Icon name="cloud"/></span><strong>{counts.squishy}</strong><span>squishies</span></div><div><span className="stat-icon green"><Icon name="grid"/></span><strong>{counts.fidget}</strong><span>fidgets</span></div><div><span className="stat-icon peach"><Icon name="heart"/></span><strong>{counts.favorite}</strong><span>favorites</span></div></div>
    <section className="collection-section" aria-label="My collection"><div className="collection-title"><h2>All my little joys <span>{data.items.length}</span></h2><button className="text-button desktop-share" disabled={!data.items.length} onClick={() => setModal('share')}><Icon name="share" size={18}/>Share my collection</button></div><div className="collection-toolbar"><div className="filters" aria-label="Filter collection">{([['all','All friends','sparkle'],['squishy','Squishies','cloud'],['fidget','Fidgets','grid'],['favorite','Favorites','heart']] as const).map(([f,label,icon]) => <button key={f} className={filter === f ? 'active' : ''} aria-pressed={filter === f} onClick={() => setFilter(f)}><Icon name={icon} size={18}/>{label}</button>)}</div><label className="search-box"><Icon name="search" size={19}/><input type="search" aria-label="Search collection" placeholder="Find a little friend…" value={query} onChange={e => setQuery(e.target.value)}/></label></div>
    {data.items.length === 0 ? <div className="empty-state"><Critter look={profile.look}/><h3>Your first little joy goes here</h3><p>Add a squishy or fidget you love. {profile.buddyName} will keep it company!</p><button className="button primary" onClick={() => setModal('add')}><Icon name="plus"/>Add my first friend</button></div> : visible.length === 0 ? <div className="empty-state compact"><Icon name="search" size={36}/><h3>No little friends found</h3><p>Try another search or peek at all your friends.</p><button className="button secondary" onClick={() => { setFilter('all'); setQuery(''); }}>Show all friends</button></div> : <div className="toy-grid">{visible.map(item => <article className="toy-card" key={item.id}><div className="toy-art" style={{ background: colors[item.color][2] }}><button id={`toy-${item.id}`} className="toy-open" aria-label={`View ${item.name}`} onClick={() => { setSelected(item); setModal('detail'); }}>{item.photo ? <img src={item.photo} alt={item.name} loading="lazy"/> : <Critter species={item.species} color={item.color}/>}</button><button className={`favorite-button ${item.favorite ? 'is-favorite' : ''}`} aria-label={`${item.favorite ? 'Unfavorite' : 'Favorite'} ${item.name}`} aria-pressed={item.favorite} disabled={busy} onClick={() => void commit({ ...data, items: data.items.map(i => i.id === item.id ? { ...i, favorite: !i.favorite } : i) }, item.favorite ? 'Removed from favorites' : 'A favorite little friend!', false)}><Icon name="heart" size={19}/></button><span className="toy-kind">{item.kind === 'squishy' ? 'SQUISHY' : 'FIDGET'}</span></div><button className="toy-name" onClick={() => { setSelected(item); setModal('detail'); }}>{item.name}<span>{species[item.species]}</span></button><div className="toy-tags">{item.tags.slice(0,2).map(t => <span key={t}>{t}</span>)}</div></article>)}<button className="add-card" onClick={() => setModal('add')}><span><Icon name="plus" size={28}/></span><strong>More room for happy</strong><small>Add a little friend</small></button></div>}
    </section><footer className="footer"><span>Made for happy hands & happy hearts.</span><button onClick={() => setModal('info')}><Icon name="lock" size={14}/>Only on your device <span>·</span> How it works <Icon name="info" size={14}/></button></footer></div></main>
    <nav className="mobile-nav" aria-label="Mobile navigation"><button onClick={() => { setFilter('all'); setQuery(''); window.scrollTo({ top: 0, behavior: 'smooth' }); }}><Icon name="shelf"/>My shelf</button><button onClick={() => setModal('buddy')}><Icon name="sparkle"/>My buddy</button><button className="mobile-add" onClick={() => setModal('add')}><Icon name="plus"/>Add friend</button><button disabled={!data.items.length} onClick={() => setModal('share')}><Icon name="share"/>Share</button></nav>
    {error && <div role="alert" className="save-error">{error}<button className="text-button" onClick={() => setError('')}>Dismiss</button></div>}<div role="status" aria-live="polite">{toast && <div className="toast"><Icon name="check" size={17}/>{toast}</div>}</div>
    {modal && <Modal title={{ onboard: 'Let’s make a little friend', buddy: 'My collection buddy', add: 'A new little friend', edit: 'A little makeover', detail: selected?.name ?? 'Little friend', share: 'Share a little happy', info: 'Your own little world', delete: 'Say goodbye?' }[modal]} close={modal === 'onboard' ? undefined : close} wide={modal === 'onboard' || modal === 'buddy'} editor={modal === 'onboard' || modal === 'buddy' || modal === 'add' || modal === 'edit'}>
      {error && <p className="error modal-error" role="alert" ref={el => el?.scrollIntoView({ block: 'nearest' })}>{error}</p>}
      {(modal === 'onboard' || modal === 'buddy') && <BuddyEditor initial={data.profile ?? undefined} onboarding={modal === 'onboard'} busy={busy} save={(p, samples) => void commit({ ...data, profile: p, items: modal === 'onboard' && samples ? sampleItems() : data.items }, modal === 'onboard' ? 'Welcome to your happy little world!' : 'Your buddy is looking lovely!').then(saved => { if (saved && modal === 'onboard') clearSetupDraft(); })}/>}
      {(modal === 'add' || modal === 'edit') && <ItemEditor initial={modal === 'edit' ? selected ?? undefined : undefined} busy={busy} save={saveItem}/>}
      {modal === 'detail' && selected && <div className="detail"><div className="detail-art" style={{ background: colors[selected.color][2] }}>{selected.photo ? <img src={selected.photo} alt={selected.name}/> : <Critter species={selected.species} color={selected.color}/>}</div><p className="eyebrow">{selected.kind} · {species[selected.species]}</p><div className="toy-tags">{selected.tags.map(t => <span key={t}>{t}</span>)}</div>{selected.notes && <div className="private-notes"><span><Icon name="lock" size={14}/>Private little notes</span><p>{selected.notes}</p></div>}<button className="button primary full" onClick={() => setModal('edit')}><Icon name="edit" size={18}/>Edit little friend</button><button className="text-button danger" onClick={() => setModal('delete')}>Remove from my shelf</button></div>}
      {modal === 'delete' && selected && <div className="detail"><p>Remove <strong>{selected.name}</strong> from your shelf? Their photo and notes will be removed too. This can’t be undone.</p><div className="form-columns"><button className="button secondary" onClick={() => setModal('detail')}>Keep my friend</button><button disabled={busy} className="button danger-button" onClick={() => void commit({ ...data, items: data.items.filter(i => i.id !== selected.id) }, 'Little friend removed')}>Remove friend</button></div></div>}
      {modal === 'share' && <ShareCollection items={data.items} attempts={shareAttempts} setAttempts={setShareAttempts}/>}
      {modal === 'info' && <div className="info-content"><div className="info-callout"><Icon name="lock" size={27}/><h3>Just yours. Right here.</h3><p>Your buddy, collection, photos and notes stay in this browser on this device. No account, ads, tracking, or social feed.</p></div><h3>Put your shelf on your home screen</h3><ol><li>Open this link in <strong>Safari</strong> on your iPhone or iPad.</li><li>Tap Safari’s <strong>Share</strong> button <Icon name="share" size={16}/>.</li><li>Choose <strong>Add to Home Screen</strong>, then <strong>Add</strong>.</li></ol><p className="small muted">Your home-screen shelf may have separate storage from your Safari tab. Start your collection in the place you’ll use it. Keep using the same device and browser.</p><h3>A little note for grown-ups</h3><p>Collections don’t sync between devices or with the native iOS app. Clearing website data, removing the home-screen app, or using Private Browsing can erase a collection. Open your shelf online once to get it ready to use offline.</p><p>Sharing asks for a grown-up’s help. Only toy names and drawings go into the picture—not your nickname, notes, buddy’s name, or photos. The math check is a speed bump, not age verification.</p><p className="small muted">The website host receives normal requests to load the app. Collection data is never uploaded.</p></div>}
    </Modal>}
  </>;
}
createRoot(document.getElementById('root')!).render(<App/>);
if (import.meta.env.PROD && 'serviceWorker' in navigator) {
  void navigator.serviceWorker.register(new URL('sw.js', document.baseURI)).catch(() => {
    console.warn('The Fidget Friends offline cache could not be prepared.');
  });
}
