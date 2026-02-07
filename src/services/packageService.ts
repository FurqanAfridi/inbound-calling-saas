import { supabase } from '../lib/supabase';

export interface Package {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  tier: 'free' | 'pro' | 'premium' | 'enterprise';
  price_monthly: number | null;
  price_yearly: number | null;
  currency: string;
  credits_included: number | null;
  is_active: boolean;
  is_featured: boolean;
  sort_order: number;
  metadata: Record<string, any>;
}

export interface PackageFeature {
  id: string;
  package_id: string;
  feature_key: string;
  feature_label: string;
  feature_template: string;
  display_order: number;
  is_highlighted: boolean;
}

export interface PackageVariable {
  id: string;
  package_id: string;
  variable_key: string;
  variable_value: string;
  variable_type: 'text' | 'number' | 'boolean' | 'currency';
}

export interface PackageWithDetails extends Package {
  features: PackageFeature[];
  variables: PackageVariable[];
}

/**
 * Render a feature template with variables
 */
export function renderFeatureTemplate(
  template: string,
  variables: PackageVariable[]
): string {
  let rendered = template;
  
  variables.forEach((variable) => {
    const regex = new RegExp(`\\{\\{${variable.variable_key}\\}\\}`, 'g');
    rendered = rendered.replace(regex, variable.variable_value);
  });
  
  return rendered;
}

/**
 * Fetch all active packages with features and variables
 */
export async function fetchPackages(): Promise<PackageWithDetails[]> {
  const { data: packages, error: packagesError } = await supabase
    .from('packages')
    .select('*')
    .eq('is_active', true)
    .order('sort_order', { ascending: true });

  if (packagesError) {
    throw packagesError;
  }

  if (!packages || packages.length === 0) {
    return [];
  }

  const packageIds = packages.map((p: Package) => p.id);

  // Fetch features
  const { data: features, error: featuresError } = await supabase
    .from('package_features')
    .select('*')
    .in('package_id', packageIds)
    .order('display_order', { ascending: true });

  if (featuresError) {
    throw featuresError;
  }

  // Fetch variables
  const { data: variables, error: variablesError } = await supabase
    .from('package_variables')
    .select('*')
    .in('package_id', packageIds);

  if (variablesError) {
    throw variablesError;
  }

  // Combine packages with their features and variables
  const packagesWithDetails: PackageWithDetails[] = packages.map((pkg: Package) => ({
    ...pkg,
    features: (features || []).filter((f: PackageFeature) => f.package_id === pkg.id),
    variables: (variables || []).filter((v: PackageVariable) => v.package_id === pkg.id),
  }));

  return packagesWithDetails;
}

/**
 * Fetch a single package by ID with features and variables
 */
export async function fetchPackageById(packageId: string): Promise<PackageWithDetails | null> {
  const { data: packageData, error: packageError } = await supabase
    .from('packages')
    .select('*')
    .eq('id', packageId)
    .single();

  if (packageError) {
    throw packageError;
  }

  if (!packageData) {
    return null;
  }

  // Fetch features
  const { data: features, error: featuresError } = await supabase
    .from('package_features')
    .select('*')
    .eq('package_id', packageId)
    .order('display_order', { ascending: true });

  if (featuresError) {
    throw featuresError;
  }

  // Fetch variables
  const { data: variables, error: variablesError } = await supabase
    .from('package_variables')
    .select('*')
    .eq('package_id', packageId);

  if (variablesError) {
    throw variablesError;
  }

  return {
    ...packageData,
    features: features || [],
    variables: variables || [],
  };
}
