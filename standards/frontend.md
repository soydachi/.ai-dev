# Estándares Frontend

## Stack base

- React 18+
- TypeScript 5.x (obligatorio)
- Vite para web
- Expo para React Native
- TanStack Query para server state
- Zustand para client state
- Tailwind CSS (web) / NativeWind (RN)

## Estructura de proyecto

```
src/
├── app/                        # Routing (Next.js App Router / Expo Router)
│   ├── (auth)/                 # Route groups
│   ├── dashboard/
│   └── layout.tsx
│
├── components/                 # Componentes reutilizables
│   ├── ui/                     # Primitivos (Button, Input, Card)
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   └── index.ts
│   ├── forms/                  # Componentes de formulario
│   └── layout/                 # Header, Footer, Sidebar
│
├── features/                   # Features por dominio
│   ├── auth/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── api.ts
│   │   └── types.ts
│   └── users/
│       ├── components/
│       ├── hooks/
│       ├── api.ts
│       └── types.ts
│
├── hooks/                      # Hooks globales
│   ├── use-debounce.ts
│   └── use-media-query.ts
│
├── lib/                        # Utilidades y configuración
│   ├── api-client.ts
│   ├── query-client.ts
│   └── utils.ts
│
├── stores/                     # Zustand stores
│   └── auth-store.ts
│
└── types/                      # Tipos globales
    └── index.ts
```

## Componentes

### Convenciones de nombrado

```typescript
// ✅ PascalCase para componentes
export function UserProfile({ user }: UserProfileProps) { }

// ✅ Archivos en kebab-case
// user-profile.tsx

// ✅ Props interface con sufijo Props
interface UserProfileProps {
  user: User;
  onEdit?: () => void;
}

// ✅ Named exports (no default)
export function Button() { }
export function Card() { }
```

### Componentes funcionales

```tsx
// ✅ Componente con tipos explícitos
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  children,
  onClick,
}: ButtonProps) {
  return (
    <button
      className={cn(
        'rounded-md font-medium transition-colors',
        variants[variant],
        sizes[size],
        isLoading && 'opacity-50 cursor-not-allowed',
      )}
      disabled={isLoading}
      onClick={onClick}
    >
      {isLoading ? <Spinner /> : children}
    </button>
  );
}

// ✅ Compound components
export function Card({ children, className }: CardProps) {
  return (
    <div className={cn('rounded-lg border bg-card', className)}>
      {children}
    </div>
  );
}

Card.Header = function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="px-6 py-4 border-b">{children}</div>;
};

Card.Content = function CardContent({ children }: { children: React.ReactNode }) {
  return <div className="px-6 py-4">{children}</div>;
};

// Uso
<Card>
  <Card.Header>Title</Card.Header>
  <Card.Content>Content</Card.Content>
</Card>
```

### Composición sobre herencia

```tsx
// ✅ Composición con children
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  children: React.ReactNode;
}

export function Modal({ isOpen, onClose, children }: ModalProps) {
  if (!isOpen) return null;
  
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div className="relative bg-white rounded-lg shadow-xl">
        {children}
      </div>
    </div>
  );
}

// ✅ Render props cuando se necesita más control
interface DataListProps<T> {
  items: T[];
  renderItem: (item: T, index: number) => React.ReactNode;
  keyExtractor: (item: T) => string;
}

export function DataList<T>({ items, renderItem, keyExtractor }: DataListProps<T>) {
  return (
    <ul>
      {items.map((item, index) => (
        <li key={keyExtractor(item)}>{renderItem(item, index)}</li>
      ))}
    </ul>
  );
}
```

## Hooks

### Custom hooks

```typescript
// ✅ Hook con tipos genéricos
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}

// ✅ Hook con cleanup
export function useClickOutside(
  ref: RefObject<HTMLElement>,
  handler: () => void,
) {
  useEffect(() => {
    const listener = (event: MouseEvent | TouchEvent) => {
      if (!ref.current || ref.current.contains(event.target as Node)) {
        return;
      }
      handler();
    };

    document.addEventListener('mousedown', listener);
    document.addEventListener('touchstart', listener);

    return () => {
      document.removeEventListener('mousedown', listener);
      document.removeEventListener('touchstart', listener);
    };
  }, [ref, handler]);
}

// ✅ Hook para async operations
export function useAsync<T>(asyncFn: () => Promise<T>, deps: unknown[] = []) {
  const [state, setState] = useState<{
    data: T | null;
    error: Error | null;
    isLoading: boolean;
  }>({
    data: null,
    error: null,
    isLoading: true,
  });

  useEffect(() => {
    let isMounted = true;
    
    setState(prev => ({ ...prev, isLoading: true }));
    
    asyncFn()
      .then(data => {
        if (isMounted) setState({ data, error: null, isLoading: false });
      })
      .catch(error => {
        if (isMounted) setState({ data: null, error, isLoading: false });
      });

    return () => { isMounted = false; };
  }, deps);

  return state;
}
```

## Server state con TanStack Query

```typescript
// ✅ Query hooks por feature
// features/users/hooks/use-users.ts
export function useUsers(params: GetUsersParams) {
  return useQuery({
    queryKey: ['users', params],
    queryFn: () => usersApi.getUsers(params),
    staleTime: 5 * 60 * 1000, // 5 minutos
  });
}

export function useUser(userId: string) {
  return useQuery({
    queryKey: ['users', userId],
    queryFn: () => usersApi.getUser(userId),
    enabled: !!userId,
  });
}

// ✅ Mutations con optimistic updates
export function useUpdateUser() {
  const queryClient = useQueryClient();
  
  return useMutation({
    mutationFn: usersApi.updateUser,
    onMutate: async (newUser) => {
      await queryClient.cancelQueries({ queryKey: ['users', newUser.id] });
      
      const previousUser = queryClient.getQueryData(['users', newUser.id]);
      queryClient.setQueryData(['users', newUser.id], newUser);
      
      return { previousUser };
    },
    onError: (err, newUser, context) => {
      queryClient.setQueryData(['users', newUser.id], context?.previousUser);
    },
    onSettled: (data, error, variables) => {
      queryClient.invalidateQueries({ queryKey: ['users', variables.id] });
    },
  });
}
```

## Client state con Zustand

```typescript
// ✅ Store tipado
interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
}

interface AuthActions {
  login: (user: User, token: string) => void;
  logout: () => void;
  updateUser: (user: Partial<User>) => void;
}

type AuthStore = AuthState & AuthActions;

export const useAuthStore = create<AuthStore>()(
  persist(
    (set) => ({
      user: null,
      token: null,
      isAuthenticated: false,
      
      login: (user, token) => set({
        user,
        token,
        isAuthenticated: true,
      }),
      
      logout: () => set({
        user: null,
        token: null,
        isAuthenticated: false,
      }),
      
      updateUser: (updates) => set((state) => ({
        user: state.user ? { ...state.user, ...updates } : null,
      })),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({ token: state.token }),
    },
  ),
);

// ✅ Selectores para evitar re-renders
const user = useAuthStore((state) => state.user);
const isAuthenticated = useAuthStore((state) => state.isAuthenticated);
```

## Forms

```tsx
// ✅ React Hook Form + Zod
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const createUserSchema = z.object({
  email: z.string().email('Email inválido'),
  name: z.string().min(2, 'Mínimo 2 caracteres'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
});

type CreateUserForm = z.infer<typeof createUserSchema>;

export function CreateUserForm({ onSubmit }: { onSubmit: (data: CreateUserForm) => void }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<CreateUserForm>({
    resolver: zodResolver(createUserSchema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <div>
        <Input
          {...register('email')}
          placeholder="Email"
          error={errors.email?.message}
        />
      </div>
      
      <div>
        <Input
          {...register('name')}
          placeholder="Nombre"
          error={errors.name?.message}
        />
      </div>
      
      <div>
        <Input
          {...register('password')}
          type="password"
          placeholder="Contraseña"
          error={errors.password?.message}
        />
      </div>
      
      <Button type="submit" isLoading={isSubmitting}>
        Crear usuario
      </Button>
    </form>
  );
}
```

## React Native específico

### Componentes cross-platform

```tsx
// ✅ Platform-specific code
import { Platform, Pressable } from 'react-native';

export function Button({ onPress, children }: ButtonProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [
        styles.button,
        pressed && styles.pressed,
        Platform.select({
          ios: styles.iosButton,
          android: styles.androidButton,
        }),
      ]}
    >
      {children}
    </Pressable>
  );
}

// ✅ Safe area handling
import { SafeAreaView } from 'react-native-safe-area-context';

export function Screen({ children }: { children: React.ReactNode }) {
  return (
    <SafeAreaView style={styles.container} edges={['top', 'bottom']}>
      {children}
    </SafeAreaView>
  );
}
```

### Navigation (Expo Router)

```tsx
// app/(tabs)/_layout.tsx
export default function TabLayout() {
  return (
    <Tabs>
      <Tabs.Screen
        name="home"
        options={{
          title: 'Home',
          tabBarIcon: ({ color }) => <HomeIcon color={color} />,
        }}
      />
      <Tabs.Screen
        name="profile"
        options={{
          title: 'Profile',
          tabBarIcon: ({ color }) => <UserIcon color={color} />,
        }}
      />
    </Tabs>
  );
}

// ✅ Type-safe navigation
import { useRouter, useLocalSearchParams } from 'expo-router';

export function UserDetail() {
  const { id } = useLocalSearchParams<{ id: string }>();
  const router = useRouter();
  
  return (
    <Button onPress={() => router.push(`/users/${id}/edit`)}>
      Edit
    </Button>
  );
}
```

## Performance

```tsx
// ✅ Memoización cuando es necesario
const MemoizedList = memo(function List({ items }: { items: Item[] }) {
  return items.map(item => <ListItem key={item.id} item={item} />);
});

// ✅ useCallback para handlers estables
function Parent() {
  const [items, setItems] = useState<Item[]>([]);
  
  const handleDelete = useCallback((id: string) => {
    setItems(prev => prev.filter(item => item.id !== id));
  }, []);
  
  return <ItemList items={items} onDelete={handleDelete} />;
}

// ✅ useMemo para cálculos costosos
function Dashboard({ data }: { data: DataPoint[] }) {
  const statistics = useMemo(() => calculateStatistics(data), [data]);
  
  return <StatsDisplay stats={statistics} />;
}

// ✅ Lazy loading
const HeavyChart = lazy(() => import('./heavy-chart'));

function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart />
    </Suspense>
  );
}
```

## Testing

```tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';

describe('CreateUserForm', () => {
  it('should submit form with valid data', async () => {
    const onSubmit = vi.fn();
    const user = userEvent.setup();
    
    render(<CreateUserForm onSubmit={onSubmit} />);
    
    await user.type(screen.getByPlaceholderText('Email'), 'test@example.com');
    await user.type(screen.getByPlaceholderText('Nombre'), 'John Doe');
    await user.type(screen.getByPlaceholderText('Contraseña'), 'password123');
    await user.click(screen.getByRole('button', { name: /crear/i }));
    
    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith({
        email: 'test@example.com',
        name: 'John Doe',
        password: 'password123',
      });
    });
  });
  
  it('should show validation errors', async () => {
    render(<CreateUserForm onSubmit={vi.fn()} />);
    
    fireEvent.click(screen.getByRole('button', { name: /crear/i }));
    
    expect(await screen.findByText(/email inválido/i)).toBeInTheDocument();
  });
});
```

## Checklist para el agente

Al escribir código frontend:

- [ ] TypeScript strict, no any
- [ ] Named exports, no default
- [ ] Props interfaces explícitas
- [ ] Custom hooks para lógica reutilizable
- [ ] TanStack Query para server state
- [ ] Zustand con selectores para client state
- [ ] React Hook Form + Zod para forms
- [ ] Memoización solo cuando es necesario
- [ ] Tests con Testing Library
- [ ] Accesibilidad (ARIA, semantic HTML)
