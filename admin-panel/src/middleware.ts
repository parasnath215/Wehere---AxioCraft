import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const PUBLIC_STATIC_EXTENSIONS = ['.png', '.svg', '.ico', '.css', '.js', '.map', '.woff2'];

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  const isPublicStatic = PUBLIC_STATIC_EXTENSIONS.some(ext => pathname.endsWith(ext));

  // Paths excluded from authentication check
  if (
    pathname.startsWith('/login') ||
    pathname.startsWith('/_next/') ||
    pathname === '/favicon.ico' ||
    pathname.startsWith('/api/admin/login') ||
    isPublicStatic
  ) {
    // If authenticated user visits /login, redirect to dashboard
    if (pathname === '/login' && request.cookies.get('admin_token')?.value) {
      return NextResponse.redirect(new URL('/', request.url));
    }
    return NextResponse.next();
  }

  const token = request.cookies.get('admin_token')?.value;

  if (!token) {
    const loginUrl = new URL('/login', request.url);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};
