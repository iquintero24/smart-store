import { ApplicationConfig, provideBrowserGlobalErrorListeners } from '@angular/core';
import { provideRouter } from '@angular/router';
import { PRIMEUI_LICENSE } from './primeui-license'; 
import Aura from '@primeuix/themes/aura';  // ← agregar

import { routes } from './app.routes';
import { providePrimeNG } from 'primeng/config';

export const appConfig: ApplicationConfig = {
  providers: [
    provideBrowserGlobalErrorListeners(),
    provideRouter(routes),
    providePrimeNG({
      theme: {
        preset: Aura
      },
      license: PRIMEUI_LICENSE   // ← agregar
    })
  ]
};
