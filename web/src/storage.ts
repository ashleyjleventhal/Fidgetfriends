import { emptyCollection, isCollection } from './model';
import type { Collection } from './model';
const dbName = 'fidget-friends';
function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(dbName, 1);
    request.onupgradeneeded = () => request.result.createObjectStore('collection');
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
    request.onblocked = () => reject(new Error('Close other Fidget Friends tabs and try again.'));
  });
}
export async function loadCollection(): Promise<Collection> {
  const db = await openDB();
  try { return await new Promise((resolve, reject) => {
    const request = db.transaction('collection', 'readonly').objectStore('collection').get('current');
    request.onsuccess = () => request.result === undefined ? resolve(structuredClone(emptyCollection)) : isCollection(request.result) ? resolve(request.result) : reject(new Error('Saved collection could not be read. It has not been overwritten.'));
    request.onerror = () => reject(request.error);
  }); } finally { db.close(); }
}
export async function saveCollection(data: Collection): Promise<void> {
  const db = await openDB();
  try { await new Promise<void>((resolve, reject) => {
    const transaction = db.transaction('collection', 'readwrite');
    transaction.objectStore('collection').put(data, 'current');
    transaction.oncomplete = () => resolve();
    transaction.onerror = () => reject(transaction.error);
    transaction.onabort = () => reject(transaction.error);
  }); } finally { db.close(); }
}
export async function resizePhoto(file: File): Promise<string> {
  if (!file.type.startsWith('image/')) throw new Error('Choose a photo, such as a JPG or PNG.');
  if (file.size > 25 * 1024 * 1024) throw new Error('That photo is too big. Try one smaller than 25 MB.');
  const url = URL.createObjectURL(file);
  try {
    const img = new Image(); img.src = url; await img.decode();
    const scale = Math.min(1, 1000 / Math.max(img.width, img.height));
    const canvas = document.createElement('canvas'); canvas.width = Math.round(img.width * scale); canvas.height = Math.round(img.height * scale);
    const ctx = canvas.getContext('2d'); if (!ctx) throw new Error('Your browser could not open this photo.');
    ctx.fillStyle = '#fff'; ctx.fillRect(0, 0, canvas.width, canvas.height); ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL('image/jpeg', 0.85);
  } catch { throw new Error('Could not open that photo. Try a JPG or PNG instead.'); } finally { URL.revokeObjectURL(url); }
}
